import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../model/Song.dart';

/// Exports a playlist as a printable PDF.
///
/// Layout per song:
///   - Title (Helvetica Bold, 16 pt)
///   - Author (Helvetica Oblique, 11 pt), when present
///   - Body in Courier 10 pt: chord lines (bold, blue) above lyric lines
///   - Chorus lines in italic
///   - One song per page (new page forced between songs; long songs flow over)
class PdfController {
  static const double _bodySize = 10.0;
  static const double _titleSize = 16.0;
  static const double _authorSize = 11.0;
  static final PdfColor _chordColor = PdfColor.fromHex('1565C0'); // blue 800

  static final _expChord = RegExp(r'\[([^\]]*)\]');
  static final _expDirectiveFull = RegExp(r'^\s*\{([^}]*)\}\s*$');
  static final _expDirectiveKV =
      RegExp(r'^\s*\{([a-zA-Z0-9_ ]+)\s*:\s*(.*?)\}\s*$');
  static final _expInlineChorus =
      RegExp(r'^\s*\{(?:soc|start_of_chorus)\}(.*)\{(?:eoc|end_of_chorus)\}\s*$');
  static final _expDirectiveName = RegExp(r'^([a-zA-Z_]+)');
  static final _expLabelAttr = RegExp(r'''label=['"]([^'"]+)['"]''');

  // ── Public API ──────────────────────────────────────────────────────────────

  static Future<void> exportPlaylistToPdf(
      List<Song> songs, String playlistTitle) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.courier(),
        bold: pw.Font.courierBold(),
        italic: pw.Font.courierOblique(),
        boldItalic: pw.Font.courierBoldOblique(),
      ),
    );

    final titleFont = pw.Font.helveticaBold();
    final authorFont = pw.Font.helveticaOblique();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];
          for (int i = 0; i < songs.length; i++) {
            if (i > 0) widgets.add(pw.NewPage());
            widgets.addAll(_buildSong(songs[i], titleFont, authorFont));
          }
          return widgets;
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final safeName =
        playlistTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: playlistTitle,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _directiveName(String raw) =>
      _expDirectiveName.firstMatch(raw.trim())?.group(1)?.toLowerCase() ?? '';

  static String? _parseLabel(String raw) =>
      _expLabelAttr.firstMatch(raw)?.group(1);

  static pw.Widget _buildSectionLabelWidget(String label) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            font: pw.Font.helveticaBold(),
            fontSize: 8,
            letterSpacing: 1.0,
            color: PdfColors.grey600,
          ),
        ),
      );

  // ── Song rendering ──────────────────────────────────────────────────────────

  static List<pw.Widget> _buildSong(
      Song song, pw.Font titleFont, pw.Font authorFont) {
    final widgets = <pw.Widget>[];

    widgets.add(pw.Text(
      song.title,
      style: pw.TextStyle(font: titleFont, fontSize: _titleSize),
    ));

    if (song.author != null && song.author!.isNotEmpty) {
      widgets.add(pw.Text(
        song.author!,
        style: pw.TextStyle(font: authorFont, fontSize: _authorSize),
      ));
    }

    // Extract subtitle, key, capo, tempo, time from body (T1-1, T1-5, T1-6)
    String? subtitle, key, capo, tempo, time;
    for (final line in song.body.split('\n')) {
      final m = _expDirectiveKV.firstMatch(line);
      if (m == null) continue;
      final k = m.group(1)!.trim().toLowerCase();
      final v = (m.group(2) ?? '').trim();
      switch (k) {
        case 'subtitle': case 'st': subtitle = v; break;
        case 'key': key = v; break;
        case 'capo': capo = v; break;
        case 'tempo': tempo = v; break;
        case 'time': time = v; break;
      }
    }

    if (subtitle != null && subtitle.isNotEmpty) {
      widgets.add(pw.Text(subtitle,
          style: pw.TextStyle(font: pw.Font.helveticaOblique(), fontSize: 10)));
    }

    final metaParts = [
      if (key != null) 'Key: $key',
      if (capo != null) 'Capo: $capo',
      if (tempo != null) '\u2669 = $tempo', // ♩
      if (time != null) time,
    ];
    if (metaParts.isNotEmpty) {
      widgets.add(pw.Text(metaParts.join('  •  '),
          style: pw.TextStyle(
              font: pw.Font.helvetica(),
              fontSize: 9,
              color: PdfColors.grey600)));
    }

    widgets.add(pw.SizedBox(height: 10));
    widgets.addAll(_buildBody(song.body));
    return widgets;
  }

  static List<pw.Widget> _buildBody(String body) {
    final widgets = <pw.Widget>[];
    bool inChorus = false;

    for (final raw in body.split('\n')) {
      // Skip comment lines
      if (raw.trimLeft().startsWith('#')) continue;

      // Inline chorus: {soc}lyrics{eoc}
      if (_expInlineChorus.hasMatch(raw)) {
        final content = _expInlineChorus.firstMatch(raw)!.group(1) ?? '';
        _addLine(widgets, content, italic: true);
        continue;
      }

      // Key-value directive MUST come before bare-directive check because
      // _expDirectiveFull also matches lines like {comment: text} (any {…}).
      // If we checked bare first, key-value directives would be silently dropped.
      if (_expDirectiveKV.hasMatch(raw)) {
        final m = _expDirectiveKV.firstMatch(raw)!;
        final key = m.group(1)!.trim().toLowerCase();
        final value = (m.group(2) ?? '').trim();
        switch (key) {
          // Shown in header — skip in body
          case 'title': case 't':
          case 'author': case 'a':
          case 'subtitle': case 'st':
          case 'key': case 'capo': case 'tempo': case 'time':
            continue;
          // Comment directives — grey italic
          case 'comment': case 'c':
          case 'comment_italic': case 'ci':
            widgets.add(pw.Text(value,
                style: pw.TextStyle(
                    font: pw.Font.courierOblique(),
                    fontSize: _bodySize,
                    color: PdfColors.grey600)));
            continue;
          case 'comment_box': case 'cb':
            widgets.add(pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey400),
                  bottom: pw.BorderSide(color: PdfColors.grey400),
                  left: pw.BorderSide(color: PdfColors.grey400),
                  right: pw.BorderSide(color: PdfColors.grey400),
                ),
              ),
              child: pw.Text(value,
                  style: pw.TextStyle(
                      font: pw.Font.courierOblique(),
                      fontSize: _bodySize,
                      color: PdfColors.grey600)),
            ));
            continue;
          default:
            // Unknown directive — bold
            widgets.add(pw.Text(
              value.isNotEmpty ? value : key,
              style: pw.TextStyle(font: pw.Font.courierBold(), fontSize: _bodySize),
            ));
            continue;
        }
      }

      // Bare directive: {soc}, {start_of_verse label="…"}, etc.
      if (_expDirectiveFull.hasMatch(raw)) {
        final full = _expDirectiveFull.firstMatch(raw)!.group(1)!.trim();
        final directive = _directiveName(full);
        final label = _parseLabel(full);
        switch (directive) {
          case 'soc':
          case 'start_of_chorus':
            if (label != null) widgets.add(_buildSectionLabelWidget(label));
            widgets.add(pw.SizedBox(height: 4));
            inChorus = true;
            break;
          case 'eoc':
          case 'end_of_chorus':
            inChorus = false;
            widgets.add(pw.SizedBox(height: 4));
            break;
          case 'sov':
          case 'start_of_verse':
            widgets.add(_buildSectionLabelWidget(label ?? 'Strofa'));
            inChorus = false;
            break;
          case 'eov':
          case 'end_of_verse':
            inChorus = false;
            break;
          case 'sob':
          case 'start_of_bridge':
            widgets.add(_buildSectionLabelWidget(label ?? 'Bridge'));
            inChorus = true;
            break;
          case 'eob':
          case 'end_of_bridge':
            inChorus = false;
            break;
        }
        continue;
      }

      // Empty line
      if (raw.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      _addLine(widgets, raw, italic: inChorus);
    }

    return widgets;
  }

  static void _addLine(List<pw.Widget> widgets, String line,
      {bool italic = false}) {
    if (_expChord.hasMatch(line)) {
      final chordLine = _buildChordLine(line);
      final lyricLine = line.replaceAll(_expChord, '');

      widgets.add(pw.Text(
        chordLine,
        style: pw.TextStyle(
          font: italic ? pw.Font.courierBoldOblique() : pw.Font.courierBold(),
          fontSize: _bodySize,
          color: _chordColor,
        ),
      ));
      widgets.add(pw.Text(
        lyricLine,
        style: pw.TextStyle(
          font: italic ? pw.Font.courierOblique() : pw.Font.courier(),
          fontSize: _bodySize,
        ),
      ));
    } else {
      widgets.add(pw.Text(
        line,
        style: pw.TextStyle(
          font: italic ? pw.Font.courierOblique() : pw.Font.courier(),
          fontSize: _bodySize,
        ),
      ));
    }
  }

  /// Builds the chord line for a raw ChordPro lyric line.
  ///
  /// Uses character-column positioning: since the body is rendered in Courier
  /// (monospace), each character occupies the same width, so chord position ==
  /// character index in the stripped lyric string.
  static String _buildChordLine(String line) {
    final buf = StringBuffer();
    int lyricsPos = 0; // column in the lyric text (chord markers removed)
    int rawPos = 0;
    int written = 0; // rightmost column written in buf so far

    for (final match in _expChord.allMatches(line)) {
      // Characters between the last chord-end and this chord-start are lyrics
      lyricsPos += match.start - rawPos;
      rawPos = match.end;

      final chord = match.group(1)!;

      // Insert at lyricsPos, but never overlap the previous chord
      final insertAt = lyricsPos > written ? lyricsPos : written;
      while (buf.length < insertAt) buf.write(' ');
      buf.write(chord);
      written = insertAt + chord.length + 1; // +1 = mandatory gap
    }

    return buf.toString();
  }
}
