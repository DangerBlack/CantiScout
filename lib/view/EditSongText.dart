import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../model/Tag.dart';
import '../Database.dart';
import '../controller/AppLocalizations.dart';

class EditSongText extends StatefulWidget {
  final Song song;
  final List<bool>? opt;

  const EditSongText({Key? key, required this.song, this.opt}) : super(key: key);

  @override
  EditSongTextState createState() => EditSongTextState();
}

class EditSongTextState extends State<EditSongText> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final myController = TextEditingController();

  late Song song;
  List<bool> opt = [];

  @override
  void initState() {
    super.initState();
    song = widget.song;
    opt = widget.opt ?? List.filled(5, false);
    myController.text = song.body;
    _loadTags();
  }

  Future<void> _loadTags() async {
    final List<Tag> tags = await DBProvider.db.getTagsBySongId(song.id);
    if (mounted) {
      setState(() => song.tags = tags);
    }
  }

  /// Save the song locally, handling both new and existing songs.
  Future<void> _saveSong(BuildContext context) async {
    final text = myController.text;
    song.body = text;

    // Parse {author: ...} from ChordPro body
    final bodyLower = text.toLowerCase();
    for (final prefix in ['{author:', '{a:']) {
      final idx = bodyLower.indexOf(prefix);
      if (idx != -1) {
        final end = text.indexOf('}', idx);
        if (end != -1) {
          final author =
              text.substring(idx + prefix.length, end).trim();
          if (author.isNotEmpty) song.author = author;
        }
        break;
      }
    }

    try {
      await DBProvider.db.updateOrInsertSong(song);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(AppLocalizations.of(context).unable_to_save),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).upload_dialog_title),
          content: Text(AppLocalizations.of(context).upload_dialog_body),
          actions: [
            TextButton(
              child: Text(
                  AppLocalizations.of(context).dialog_cancel.toUpperCase()),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: Text(
                  AppLocalizations.of(context).dialog_confirm.toUpperCase()),
              onPressed: () {
                Navigator.of(ctx).pop();
                _saveSong(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
      ),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).edit_song + song.title,
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            controller: myController,
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showConfirmDialog(context),
        tooltip: AppLocalizations.of(context).save,
        child: const Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }
}
