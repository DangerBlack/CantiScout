import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Song.dart';
import '../model/Tag.dart';
import '../model/Constants.dart';
import '../model/Chartset.dart';
import '../model/Choice.dart';
import '../Database.dart';
import '../controller/CustomSearchDelegate.dart';
import '../view/ChoosePlaylist.dart';
import '../view/EditSongText.dart';
import '../view/Settings.dart';
import '../controller/AppLocalizations.dart';

class SongText extends StatefulWidget {
  final Song song;

  const SongText({Key? key, required this.song}) : super(key: key);

  @override
  SongTextState createState() => SongTextState(this.song);
}

class SongTextState extends State<SongText> {
  final RegExp expChord = RegExp(r'\[([^\]]*)\]');
  final RegExp expComment = RegExp(r'.*\{(.*)\}.*');
  final RegExp expCommentL = RegExp(r'.*\{([a-zA-Z0-9_ ]*):(.*)\}.*');
  final RegExp expInlineChorus =
      RegExp(r'.*\{(soc|start_of_chorus)\}(.*)\{(eoc|end_of_chorus)\}.*');

  Song song;
  double fSize = Constants.initialFontSize;
  FontWeight fWeight = FontWeight.normal;
  FontStyle fStyle = FontStyle.normal;
  bool _autoscroll = Constants.initialAutoscroll;
  Color _noteColor = Color(Constants.initialColor);
  double _speed = Constants.initialAutoscrollSpeed;
  String _fontFamily = Constants.initialFontStyle;

  double? previousfSize;
  late ScrollController _controller;
  List<Choice> choices = [];

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
      _speed = newSpeed;
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

  void _select(Choice choice) {
    if (choice.action != null) choice.action!(context);
  }

  // ── Share / export ─────────────────────────────────────────────────────────

  void _showShareDialog(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Testo'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _shareSongText();
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text('File'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportChordPro();
                    },
                  ),
                ],
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
    choices = [
      Choice(
        title: AppLocalizations.of(context).settings,
        icon: Icons.settings,
        action: (context) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SettingsStateful(
                    title: AppLocalizations.of(context).settings)),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          // Autoscroll toggle
          IconButton(
            icon: Icon(_autoscroll
                ? Constants.autoscrollIconPause
                : Constants.autoscrollIcon),
            tooltip: _autoscroll ? 'Pausa scorrimento' : 'Scorrimento automatico',
            onPressed: _toggleAutoscroll,
          ),
          // Share / QR
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: AppLocalizations.of(context).share ?? 'Condividi',
            onPressed: () => _showShareDialog(context),
          ),
          // Export .chopro
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Esporta .chopro',
            onPressed: _exportChordPro,
          ),
          PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: ListTile(
                    leading: Icon(choice.icon),
                    title: Text(choice.title),
                  ),
                );
              }).toList();
            },
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

  List<Widget> _buildSongRow(String row) {
    final List<Widget> resp = [];
    if (expComment.hasMatch(row)) {
      if (expCommentL.hasMatch(row)) {
        final Match? m = expCommentL.firstMatch(row);
        if (m != null && m.groupCount > 1) {
          final String head = (m.group(1) ?? '').trim();
          final String tail = m.group(2) ?? '';
          var fStyleEdit = fStyle;
          var fWeightEdit = fWeight;
          if (head == 'author' || head == 'a') {
            fStyleEdit = FontStyle.italic;
          } else {
            fWeightEdit = FontWeight.bold;
          }
          resp.add(Text(
            tail,
            style: TextStyle(
                fontSize: fSize,
                fontWeight: fWeightEdit,
                fontStyle: fStyleEdit,
                fontFamily: _fontFamily),
          ));
        }
      } else {
        if (expInlineChorus.hasMatch(row)) {
          final Match? m = expInlineChorus.firstMatch(row);
          if (m != null && m.groupCount > 1) {
            final String body = m.group(2) ?? '';
            resp.add(Text('',
                style:
                    TextStyle(fontSize: fSize, fontWeight: FontWeight.bold)));
            if (expChord.hasMatch(body)) {
              fStyle = FontStyle.italic;
              resp.addAll(_buildSongChordRow(body));
              fStyle = FontStyle.normal;
            } else {
              resp.add(Text(body,
                  style: TextStyle(
                      fontSize: fSize,
                      fontStyle: FontStyle.italic,
                      fontFamily: _fontFamily)));
            }
            resp.add(Text('',
                style:
                    TextStyle(fontSize: fSize, fontWeight: FontWeight.bold)));
          }
        } else {
          final Match? m = expComment.firstMatch(row);
          if (m != null && m.groupCount >= 1) {
            final String head = (m.group(1) ?? '').trim();
            if (head == 'soc' || head == 'start_of_chorus') {
              resp.add(Text('', style: TextStyle(fontSize: fSize)));
              fStyle = FontStyle.italic;
              if (row.length > ('{$head}').length) {
                resp.addAll(
                    _buildSongChordRow(row.replaceAll('{$head}', '')));
              }
            }
            if (head == 'eoc' || head == 'end_of_chorus') {
              resp.add(Text('',
                  style: TextStyle(
                      fontSize: fSize,
                      fontWeight: fWeight,
                      fontStyle: fStyle)));
              fStyle = FontStyle.normal;
              if (row.length > ('{$head}').length) {
                resp.addAll(
                    _buildSongChordRow(row.replaceAll('{$head}', '')));
              }
            }
          }
        }
      }
    } else {
      if (expChord.hasMatch(row)) {
        resp.addAll(_buildSongChordRow(row));
      } else {
        resp.add(Text(
          row,
          style: TextStyle(
              fontSize: fSize,
              fontWeight: fWeight,
              fontStyle: fStyle,
              fontFamily: _fontFamily),
        ));
      }
    }
    return resp;
  }

  Widget _buildSong(BuildContext context) {
    final List<Widget> w = [];
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
                delegate: CustomSearchDelegate.builder(t.tag),
              );
            },
          );
        }).toList(),
      ));
    }

    w.add(const Divider());
    w.add(Row(children: [
      Expanded(
        child: Ink(
          decoration: ShapeDecoration(
            color: Theme.of(context).primaryColor,
            shape: const CircleBorder(),
          ),
          child: IconButton(
            color: Colors.white,
            icon: const Icon(Icons.playlist_add),
            iconSize: 30.0,
            tooltip: AppLocalizations.of(context).add_to_playlist,
            padding: const EdgeInsets.all(15.0),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChoosePlaylistStateful(
                    title: AppLocalizations.of(context).text_title,
                    song: song,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ]));

    w.add(const Padding(padding: EdgeInsets.symmetric(vertical: 20.0)));

    return GestureDetector(
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
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    super.dispose();
  }
}
