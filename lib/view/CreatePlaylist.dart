import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../view/SongUlPlaylistStateless.dart';
import '../Database.dart';
import '../controller/AppLocalizations.dart';

class CreatePlaylistStatefull extends StatefulWidget {
  const CreatePlaylistStatefull({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  CreatePlaylist createState() => CreatePlaylist();
}

class CreatePlaylist extends State<CreatePlaylistStatefull> {
  final myController = TextEditingController();
  bool _validate = false;

  Future<void> _routeToPlaylist(BuildContext context, String title, int id) async {
    final List<Song> songs = await DBProvider.db.getAllPlaylistSongs(id);
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              SongUlPlaylistStateless(songs, title, id)),
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final text = myController.text;
    if (text.isNotEmpty) {
      final int id = await DBProvider.db.newPlaylist(text);
      if (!mounted) return;
      _routeToPlaylist(context, text, id);
      _validate = false;
    } else {
      setState(() => _validate = true);
    }
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(children: [
          const Hero(
            tag: 'hero',
            child: Padding(
              padding: EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 48.0,
                child: Icon(Icons.album),
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context).name_playlist,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: TextField(
              textAlign: TextAlign.center,
              controller: myController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).playlist_name,
                errorText: _validate
                    ? AppLocalizations.of(context).value_must_not_be_empty
                    : null,
              ),
            ),
          ),
          Row(children: [
            Expanded(
              child: TextButton(
                child: Text(
                  AppLocalizations.of(context).undo,
                  style: const TextStyle(color: Colors.grey),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: TextButton(
                child: Text(
                  AppLocalizations.of(context).create,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () => _createPlaylist(context),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
