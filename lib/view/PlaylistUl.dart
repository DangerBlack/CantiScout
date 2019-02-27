import 'package:flutter/material.dart';
import 'SongUl.dart';
import '../Database.dart';
import '../model/Song.dart';
import '../model/Playlist.dart';

class PlaylistUlStateful extends StatefulWidget {
  PlaylistUlStateful({Key key, this.title}) : super(key: key);
  final String title;

  @override
  PlaylistUl createState() => PlaylistUl();
}

class PlaylistUl extends State {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  List<Playlist> l = new List<Playlist>();

  PlaylistUl() : super() {
    updateList();
  }

  updateList() async {
    //TODO: lista
    if (l.isEmpty) {
      List<Playlist> lg = await DBProvider.db.getAllPlaylist();
      setState(() {
        l = lg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //updateList();
    return Scaffold(
      appBar: AppBar(
        title: Text("Elenco Playlist"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              /*showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );*/
            },
          ),
        ],
      ),
      body: buildList(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add playlist',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlaylistRow(Playlist pair) {
    return ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(
          pair.title,
          style: _biggerFont,
        ),
        onTap: () {
          /*Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SongText(song: pair)),
          );*/
        });
  }

  Widget buildList() {
    if (l.isEmpty) {
      return Center(
        child: Text('There is no playlist right now...'),
      );
    } else {
      return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: l.length * 2,
          itemBuilder: /*1*/ (context, i) {
            if (i.isOdd) return Divider();
            /*2*/
            int index = i ~/ 2;
            if (index <= l.length) {
              var s = l[index];
              return _buildPlaylistRow(s);
            } else {
              //TODO: Statement unreachable!!!!
              return null;
            }
          });
    }
  }
}