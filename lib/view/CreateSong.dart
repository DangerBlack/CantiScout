import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../view/EditSongText.dart';
import '../controller/AppLocalizations.dart';

class CreateSongStatefull extends StatefulWidget {
  CreateSongStatefull({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  CreateSong createState() => CreateSong();
//_MyHomePageState createState() => _MyHomePageState();
}

class CreateSong extends State {
  final myController = TextEditingController();
  bool _validate = false;

  routePlaylistSong(BuildContext context, String title) async {
    //TODO: Aprire playlist appena creata!
    Song song = new Song();
    song.title = title;
    song.body = "{title: " + title + "}\n";
    song.body += "\n";
    song.body += "\n";
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditSongText(song: song, opt:_opt)),
    );
  }

  createPlaylist(BuildContext context) async {
    var text = myController.text;
    if (text.isNotEmpty) {
      print(text);
      routePlaylistSong(context, text);
      _validate = false;
    } else {
      setState(() {
        _validate = true;
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    myController.dispose();
    super.dispose();
  }

  List<bool> _opt = <bool>[false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    //updateList();
    return Scaffold(
      body: Center(
        child: ListView(children: [
          new Hero(
            tag: 'hero',
            child: Padding(
              padding: EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 48.0,
                child:
                    Icon(Icons.album), //Image.asset('assets/flutter-icon.png'),
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context).chose_title,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: EdgeInsets.all(40.0),
            child: TextField(
              textAlign: TextAlign.center,
              controller: myController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).text_title,
                errorText: _validate ? AppLocalizations.of(context).value_must_not_be_empty : null,
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context).choose_scope,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: EdgeInsets.only(top: 40.0, bottom:40.0,left:40.0, right:40.0),
            child: Row(children: [
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context).church),
                    Checkbox(
                        value: _opt[0],
                        onChanged: (value) => setState(() {
                              _opt[0] = value;
                            })),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context).lc),
                    Checkbox(
                        value: _opt[1],
                        onChanged: (value) => setState(() {
                              _opt[1] = value;
                            })),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context).eg),
                    Checkbox(
                        value: _opt[2],
                        onChanged: (value) => setState(() {
                              _opt[2] = value;
                            })),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context).rs),
                    Checkbox(
                        value: _opt[3],
                        onChanged: (value) => setState(() {
                              _opt[3] = value;
                            })),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context).other),
                    Checkbox(
                        value: _opt[4],
                        onChanged: (value) => setState(() {
                              _opt[4] = value;
                            })),
                  ],
                ),
              ),
            ]),
          ),
          Row(children: [
            Expanded(
              child: FlatButton(
                child: Text(
                  AppLocalizations.of(context).undo,
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: FlatButton(
                child: Text(
                  AppLocalizations.of(context).create,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                onPressed: () {
                  createPlaylist(context);
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
