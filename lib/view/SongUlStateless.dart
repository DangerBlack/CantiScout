import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../model/SongList.dart';
import '../model/User.dart';
import '../view/SongText.dart';
import '../view/CreateSong.dart';
import '../controller/CustomSearchDelegate.dart';
import '../controller/AppLocalizations.dart';
import '../controller/Utils.dart';
import '../model/Constants.dart';

class SongUlStateless extends StatelessWidget {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final User user;
  final String title; // = "Elenco canzoni";
  final SongList l = new SongList();

  SongUlStateless(List<Song> songs, this.title, this.user) : super() {
    //this.title = title;
    //this.user = user;
    this.l.list = songs;
    //updateList(songs);
  }

  updateList(List<Song> songs) {
    this.l.list = songs;
  }

  @override
  Widget build(BuildContext context) {
    //updateList();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: buildList(context),
      floatingActionButton: user.logged
          ? FloatingActionButton(
              onPressed: () => _showConfirmDialog(context),
              tooltip: AppLocalizations.of(context).add,
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(AppLocalizations.of(context).create_dialog_title),
          content: new Container(
            height: 200,
            width: 200,
            child: new Center(
              child: new ListView(
                scrollDirection: Axis.vertical,
                children: <Widget>[
                  new Text(AppLocalizations.of(context).create_dialog_body),
                  new Text(""),
                  new Text(
                      AppLocalizations.of(context).create_dialog_body_sample,
                      style: TextStyle(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.left),
                  new FlatButton(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        new Text(
                          AppLocalizations.of(context).create_dialog_body_more +
                              " ",
                          style: TextStyle(fontSize: 17),
                        ),
                        Text(
                          "ChordPro",
                          style: TextStyle(
                            fontSize: 17,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () => Utils.launchURL(Constants.urlChordPro),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text(
                  AppLocalizations.of(context).dialog_confirm.toUpperCase()),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateSongStatefull(
                        title: AppLocalizations.of(context).create_song),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildSongRow(BuildContext context, Song pair, int index) {
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(
        pair.title,
        style: _biggerFont,
      ),
      subtitle: Text(
        pair.author ?? "",
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SongText(song: pair)),
        );
      },
      onLongPress: () {
        print("wow!");
      },
    );
  }

  Widget buildList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: l.list.length * 2,
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return Divider();
          /*2*/
          int index = i ~/ 2;
          if (index <= l.list.length) {
            var s = l.get(index);
            return buildSongRow(context, s, index);
          } else {
            //TODO: Statement unreachable!!!!
            return null;
          }
        });
  }
}
