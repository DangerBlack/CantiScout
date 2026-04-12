import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Song.dart';
import '../model/Tag.dart';
import '../model/Constants.dart';
import '../model/Chartset.dart';
import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/CustomSearchDelegate.dart';
import '../controller/SongValidator.dart';
import '../view/ChoosePlaylist.dart';
import '../view/EditSongText.dart';

class SongText extends StatefulWidget {
  final Song song;

  const SongText({Key? key, required this.song}) : super(key: key);

  @override
  SongTextState createState() => SongTextState(this.song);
}

class SongTextState extends State<SongText> {
  static final RegExp expChord = RegExp(r'\[([^\]]*)\]');
  static final RegExp expComment = RegExp(r'.*\{(.*)\}.*');
  static final RegExp expCommentL = RegExp(r'.*\{([a-zA-Z0-9_ ]*):(.*)\}.*');
  static final RegExp expInlineChorus =
      RegExp(r'.*\{(soc|start_of_chorus)\}(.*)\{(eoc|end_of_chorus)\}.*');
  // Matches bare directives (no colon) with optional attributes, e.g. {sov label="Strofa 1"}
  // \s* allows a space after { (e.g. { soc} found in some song bodies)
  static final RegExp _expBareDir = RegExp(r'\{\s*([a-zA-Z_]+)([^}:]*)\}');
  static final RegExp _expLabelAttr = RegExp(r'''label=['"]([^'"]+)['"]''');

  Song song;
  double fSize = Constants.initialFontSize;
  FontWeight fWeight = FontWeight.normal;
  FontStyle fStyle = FontStyle.normal;
  bool _autoscroll = Constants.initialAutoscroll;
  Color _noteColor = Color(Constants.initialColor);
  double _speed = Constants.initialAutoscrollSpeed;
  String _fontFamily = Constants.initialFontStyle;

  double? previousfSize;
  bool _validationBannerDismissed = false;
  late ScrollController _controller;

  SongTextState(this.song);

  Future<void> _loadTags() async {
    final List<Tag> tags = await DBProvider.db.getTagsBySongId(song.id);
    if (mounted) setState(() => song.tags = tags);
  }

  Future<void> _loadFontConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final newFSize = prefs.getDouble(Constants.sharedDefaultFontSize) ??
        Constants.initialFontSize;
    final newAutoscroll =
        prefs.getBool(Constants.sharedAutoscroll) ?? Constants.initialAutoscroll;
    final newNoteColor =
        Color(prefs.getInt(Constants.sharedFontColor) ?? Constants.initialColor);
    final newFontFamily =
        prefs.getString(Constants.sharedFontStyle) ?? Constants.initialFontStyle;
    final newSpeed = prefs.getDouble(Constants.sharedAutoscrollSpeed) ??
        Constants.initialAutoscrollSpeed;

    if (!mounted) return;
    setState(() {
      fSize = newFSize;
      _autoscroll = newAutoscroll;
      _noteColor = newNoteColor;
      _fontFamily = newFontFamily;
      _speed = newSpeed.clamp(0.0, Constants.maxScrollSpeed);
    });
    // Start autoscroll after the first frame so maxScrollExtent is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runScroller());
  }

  /// Animate to the bottom at a speed proportional to _speed.
  /// Uses the actual scroll extent rather than a widget count estimate.
  void _runScroller() {
    if (!_controller.hasClients) return;
    if (!_autoscroll || _speed <= 0) {
      // Cancel any ongoing animation by jumping to current position.
      _controller.jumpTo(_controller.offset);
      return;
    }

    final maxExtent = _controller.position.maxScrollExtent;
    final remaining = maxExtent - _controller.offset;
    if (remaining <= 0) return;

    // px/s = _speed * scrollMultiplier  (e.g. speed 5 → 125 px/s)
    final pxPerSec = _speed * Constants.scrollMultiplier;
    final durationMs = (remaining / pxPerSec * 1000).floor();
    if (durationMs <= 0) return;

    _controller.animateTo(
      maxExtent,
      curve: Curves.linear,
      duration: Duration(milliseconds: durationMs),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _loadTags();
    _loadFontConfiguration();
    WakelockPlus.enable();
  }

  void _toggleAutoscroll() {
    setState(() => _autoscroll = !_autoscroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runScroller());
  }

  // ── Share / export ─────────────────────────────────────────────────────────

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Condividi testo'),
              onTap: () {
                Navigator.pop(ctx);
                _shareSongText();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Esporta .chopro'),
              onTap: () {
                Navigator.pop(ctx);
                _exportChordPro();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('QR code'),
              onTap: () {
                Navigator.pop(ctx);
                _showQrDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    final qrData = song.body;
    final tooLarge = qrData.length > 2900;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(song.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              if (song.author != null)
                Text(song.author!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (tooLarge)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Canzone troppo lunga per il QR code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                )
              else
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 260,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context).done),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareSongText() {
    final text = '${song.title}'
        '${song.author != null ? ' — ${song.author}' : ''}'
        '\n\n${song.body}';
    Share.share(text);
  }

  Future<void> _exportChordPro() async {
    final safeTitle =
        song.title.replaceAll(RegExp(r'[^\w\s\-]'), '_').trim();
    // Write to a real temp file so the OS respects the .chopro extension.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$safeTitle.chopro');
    await file.writeAsString(song.body);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/octet-stream')],
      subject: song.title,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          IconButton(
            icon: Icon(_autoscroll
                ? Constants.autoscrollIconPause
                : Constants.autoscrollIcon),
            tooltip:
                _autoscroll ? 'Pausa scorrimento' : 'Scorrimento automatico',
            onPressed: _toggleAutoscroll,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: AppLocalizations.of(context).share,
            onPressed: () => _showShareSheet(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'playlist') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChoosePlaylistStateful(
                      title: AppLocalizations.of(context).text_title,
                      song: song,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'playlist',
                child: ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: Text(AppLocalizations.of(context).add_to_playlist),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildSong(context),
          // Speed slider: shown on the right side when autoscroll is active
          if (_autoscroll)
            Positioned(
              right: 4,
              top: 0,
              bottom: 80, // leave room above FAB
              child: Center(
                child: SizedBox(
                  height: 200,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Slider(
                      value: _speed,
                      min: 0,
                      max: Constants.maxScrollSpeed,
                      divisions: (Constants.maxScrollSpeed * 10).toInt(),
                      onChanged: (value) {
                        setState(() => _speed = value);
                        _runScroller();
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Edit FAB always anchored at bottom-right
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditSongText(song: song),
            ),
          );
        },
        tooltip: AppLocalizations.of(context).edit,
        child: const Icon(Icons.edit),
      ),
    );
  }

  // ── Song rendering ─────────────────────────────────────────────────────────

  double _sumSpace(String text, Map<String, double> charset) {
    double sum = 0;
    for (final ch in text.split('')) {
      sum += charset[ch] ?? 1.0;
    }
    return sum;
  }

  String _space(
      String text, String chords, String chord, String prevChord) {
    double sum = _sumSpace(text, Charset.getFont(_fontFamily));
    double def = _sumSpace(prevChord, Charset.getFontBold(_fontFamily));
    sum -= def;
    int i = 1;
    while (i < sum.round()) {
      chords += ' ';
      i++;
    }
    if (chords.isNotEmpty && chords[chords.length - 1] != ' ') {
      chords += ' ';
    }
    chords += chord;
    return chords;
  }

  List<Widget> _buildSongChordRow(String row) {
    final List<Widget> resp = [];
    String chord = '';
    String text = row;
    final Iterable<Match> matches = expChord.allMatches(row);
    int prevP = 0;
    String prevChord = '';
    for (final Match m in matches) {
      final String match = m.group(0)!;
      final int p = text.indexOf(match);
      text = text.replaceFirst(match, '');
      final String chordName = match.substring(1, match.length - 1);
      chord = _space(text.substring(prevP, p), chord, chordName, prevChord);
      prevP = p;
      prevChord = chordName;
    }
    resp.add(Text(
      chord,
      style: TextStyle(
          fontSize: fSize,
          fontWeight: FontWeight.bold,
          fontStyle: fStyle,
          color: _noteColor,
          fontFamily: _fontFamily),
      overflow: TextOverflow.ellipsis,
    ));
    resp.add(Text(
      text,
      style: TextStyle(
          fontSize: fSize,
          fontWeight: fWeight,
          fontStyle: fStyle,
          fontFamily: _fontFamily),
    ));
    return resp;
  }

  // ── Section / metadata helpers ──────────────────────────────────────────────

  String? _parseLabel(String attrs) =>
      _expLabelAttr.firstMatch(attrs)?.group(1);

  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.grey[600],
            fontFamily: _fontFamily,
          ),
        ),
      );

  Widget _buildMetadataBadge(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        margin: const EdgeInsets.only(right: 6, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fSize * 0.75,
            color: Colors.grey[700],
            fontFamily: _fontFamily,
          ),
        ),
      );

  // ── Row renderer ─────────────────────────────────────────────────────────────

  List<Widget> _buildSongRow(String row) {
    final List<Widget> resp = [];

    // Skip comment lines
    if (row.trimLeft().startsWith('#')) return resp;

    // ── Key-value directive: {key: value} ────────────────────────────────────
    if (expCommentL.hasMatch(row)) {
      final m = expCommentL.firstMatch(row)!;
      final key = m.group(1)!.trim().toLowerCase();
      final value = (m.group(2) ?? '').trim();
      switch (key) {
        // Metadata directives — shown in header/body-header, skip in body
        case 'title':
        case 't':
        case 'author':
        case 'a':
        case 'key':
        case 'capo':
        case 'subtitle':
        case 'st':
        case 'tempo':
        case 'time':
          return resp;
        // Comment directives — grey italic
        case 'comment':
        case 'c':
        case 'comment_italic':
        case 'ci':
          resp.add(Text(value,
              style: TextStyle(
                  fontSize: fSize,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                  fontFamily: _fontFamily)));
          return resp;
        case 'comment_box':
        case 'cb':
          resp.add(Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: fSize,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                    fontFamily: _fontFamily)),
          ));
          return resp;
        default:
          // Unknown directive — render value in bold (catch-all)
          resp.add(Text(value,
              style: TextStyle(
                  fontSize: fSize,
                  fontWeight: FontWeight.bold,
                  fontStyle: fStyle,
                  fontFamily: _fontFamily)));
          return resp;
      }
    }

    // ── Inline chorus: {soc}lyrics{eoc} ─────────────────────────────────────
    if (expInlineChorus.hasMatch(row)) {
      final body = expInlineChorus.firstMatch(row)!.group(2) ?? '';
      resp.add(Text('', style: TextStyle(fontSize: fSize)));
      final prevStyle = fStyle;
      fStyle = FontStyle.italic;
      if (expChord.hasMatch(body)) {
        resp.addAll(_buildSongChordRow(body));
      } else {
        resp.add(Text(body,
            style: TextStyle(
                fontSize: fSize,
                fontStyle: FontStyle.italic,
                fontFamily: _fontFamily)));
      }
      fStyle = prevStyle;
      resp.add(Text('', style: TextStyle(fontSize: fSize)));
      return resp;
    }

    // ── Bare directive: {soc}, {start_of_verse label="Strofa 1"}, etc. ───────
    if (expComment.hasMatch(row)) {
      final m = _expBareDir.firstMatch(row);
      if (m != null) {
        final directive = m.group(1)!.toLowerCase();
        final attrs = m.group(2) ?? '';
        final label = _parseLabel(attrs);
        switch (directive) {
          case 'soc':
          case 'start_of_chorus':
            if (label != null) resp.add(_buildSectionLabel(label));
            resp.add(Text('', style: TextStyle(fontSize: fSize)));
            fStyle = FontStyle.italic;
            break;
          case 'eoc':
          case 'end_of_chorus':
            resp.add(Text('', style: TextStyle(fontSize: fSize)));
            fStyle = FontStyle.normal;
            break;
          case 'sov':
          case 'start_of_verse':
            resp.add(_buildSectionLabel(label ?? 'Strofa'));
            fStyle = FontStyle.normal;
            break;
          case 'eov':
          case 'end_of_verse':
            fStyle = FontStyle.normal;
            break;
          case 'sob':
          case 'start_of_bridge':
            resp.add(_buildSectionLabel(label ?? 'Bridge'));
            fStyle = FontStyle.italic;
            break;
          case 'eob':
          case 'end_of_bridge':
            fStyle = FontStyle.normal;
            break;
        }
      }
      // Render any lyric/chord content on the same line as the directive
      // e.g. "{soc}[Do]Verse text" or "[Sol]last line{eoc}"
      final rest = row.replaceAll(_expBareDir, '').trim();
      if (rest.isNotEmpty) {
        if (expChord.hasMatch(rest)) {
          resp.addAll(_buildSongChordRow(rest));
        } else {
          resp.add(Text(rest,
              style: TextStyle(
                  fontSize: fSize,
                  fontWeight: fWeight,
                  fontStyle: fStyle,
                  fontFamily: _fontFamily)));
        }
      }
      return resp;
    }

    // ── Regular content line ─────────────────────────────────────────────────
    if (expChord.hasMatch(row)) {
      resp.addAll(_buildSongChordRow(row));
    } else {
      resp.add(Text(row,
          style: TextStyle(
              fontSize: fSize,
              fontWeight: fWeight,
              fontStyle: fStyle,
              fontFamily: _fontFamily)));
    }
    return resp;
  }

  Widget _buildSong(BuildContext context) {
    final List<Widget> w = [];

    // ── Metadata pre-pass ────────────────────────────────────────────────────
    String? songKey, songCapo, songSubtitle, songTempo, songTime;
    for (final line in song.body.split('\n')) {
      final m = expCommentL.firstMatch(line);
      if (m == null) continue;
      final k = m.group(1)!.trim().toLowerCase();
      final v = (m.group(2) ?? '').trim();
      switch (k) {
        case 'key': songKey = v; break;
        case 'capo': songCapo = v; break;
        case 'subtitle': case 'st': songSubtitle = v; break;
        case 'tempo': songTempo = v; break;
        case 'time': songTime = v; break;
      }
    }

    // ── Validation banner ────────────────────────────────────────────────────
    if (!_validationBannerDismissed &&
        SongValidator.validate(song.body).isNotEmpty) {
      w.add(GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditSongText(song: song)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade400),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Canzone con problemi di formattazione — tocca per modificare',
                  style: TextStyle(
                      fontSize: fSize * 0.85,
                      color: Colors.amber.shade900),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _validationBannerDismissed = true),
                child: Icon(Icons.close,
                    size: 18, color: Colors.amber.shade700),
              ),
            ],
          ),
        ),
      ));
    }

    // Subtitle (T1-5)
    if (songSubtitle != null) {
      w.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(songSubtitle,
            style: TextStyle(
                fontSize: fSize * 0.9,
                fontStyle: FontStyle.italic,
                fontFamily: _fontFamily)),
      ));
    }

    // Metadata badges: key, capo, tempo, time (T1-1, T1-6)
    final badges = <Widget>[];
    if (songKey != null) badges.add(_buildMetadataBadge('Key: $songKey'));
    if (songCapo != null) badges.add(_buildMetadataBadge('Capo: $songCapo'));
    if (songTempo != null) badges.add(_buildMetadataBadge('♩ = $songTempo'));
    if (songTime != null) badges.add(_buildMetadataBadge(songTime));
    if (badges.isNotEmpty) {
      w.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(children: badges),
      ));
    }

    // ── Title + author header (always shown, not truncated by AppBar) ────────
    w.add(Text(
      song.title,
      style: TextStyle(
          fontSize: fSize + 2,
          fontWeight: FontWeight.bold,
          fontFamily: _fontFamily),
    ));
    if (song.author != null && song.author!.isNotEmpty) {
      w.add(Text(
        song.author!,
        style: TextStyle(
            fontSize: fSize,
            fontStyle: FontStyle.italic,
            fontFamily: _fontFamily),
      ));
    }

    // ── Body lines ───────────────────────────────────────────────────────────
    // Reset section style before rendering (avoids state leak across songs)
    fStyle = FontStyle.normal;
    for (final line in song.body.split('\n')) {
      w.addAll(_buildSongRow(line));
    }

    // Tags section
    if (song.tags.isNotEmpty) {
      w.add(const Divider());
      w.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          '${AppLocalizations.of(context).tags}:',
          style: const TextStyle(fontSize: 18.0),
        ),
      ));
      w.add(Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: song.tags.map((t) {
          return ActionChip(
            label: Text('#${t.tag}'),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(initialQuery: t.tag),
              );
            },
          );
        }).toList(),
      ));
    }

    w.add(const Padding(padding: EdgeInsets.symmetric(vertical: 20.0)));

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        // Pause autoscroll when the user manually scrolls
        if (_autoscroll && notification.direction != ScrollDirection.idle) {
          setState(() => _autoscroll = false);
          _controller.jumpTo(_controller.offset);
        }
        return false;
      },
      child: GestureDetector(
        onScaleStart: (_) => setState(() => previousfSize = fSize),
        onScaleUpdate: (ScaleUpdateDetails d) {
          setState(() => fSize = (previousfSize ?? fSize) * d.scale);
        },
        child: ListView(
          controller: _controller,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 48.0, 20.0),
          children: w,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    super.dispose();
  }
}
