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
  static final _expTitleAuthor =
      RegExp(r'^\s*\{(?:title|t|author|a)\s*:', caseSensitive: false);

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

    widgets.add(pw.SizedBox(height: 10));
    widgets.addAll(_buildBody(song.body));
    return widgets;
  }

  static List<pw.Widget> _buildBody(String body) {
    final widgets = <pw.Widget>[];
    bool inChorus = false;

    for (final raw in body.split('\n')) {
      // Skip title / author directives already rendered in the header
      if (_expTitleAuthor.hasMatch(raw)) continue;

      // Inline chorus: {soc}lyrics{eoc}
      if (_expInlineChorus.hasMatch(raw)) {
        final content = _expInlineChorus.firstMatch(raw)!.group(1) ?? '';
        _addLine(widgets, content, italic: true);
        continue;
      }

      // Bare directive: {soc}, {eoc}, etc.
      if (_expDirectiveFull.hasMatch(raw)) {
        final directive =
            _expDirectiveFull.firstMatch(raw)!.group(1)!.trim().toLowerCase();
        if (directive == 'soc' || directive == 'start_of_chorus') {
          widgets.add(pw.SizedBox(height: 4));
          inChorus = true;
        } else if (directive == 'eoc' || directive == 'end_of_chorus') {
          inChorus = false;
          widgets.add(pw.SizedBox(height: 4));
        }
        // other bare directives are ignored
        continue;
      }

      // Key-value directive: {key: value}
      if (_expDirectiveKV.hasMatch(raw)) {
        final m = _expDirectiveKV.firstMatch(raw)!;
        final key = m.group(1)!.trim().toLowerCase();
        if (key == 'title' || key == 't' || key == 'author' || key == 'a') {
          continue;
        }
        final value = m.group(2) ?? '';
        widgets.add(pw.Text(
          value.isNotEmpty ? value : key,
          style: pw.TextStyle(
              font: pw.Font.courierBold(), fontSize: _bodySize),
        ));
        continue;
      }

      // Comment line
      if (raw.trimLeft().startsWith('#')) continue;

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
