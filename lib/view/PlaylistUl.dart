import 'package:flutter/material.dart';
import 'SongUl.dart';
import '../Database.dart';
import '../model/Song.dart';
import '../model/Playlist.dart';
import 'Createplaylist.dart';
import 'SongULStateless.dart';

class PlaylistUlStateful extends StatefulWidget {
  PlaylistUlStateful({Key key, this.title}) : super(key: key);
  final String title;

  @override
  PlaylistUl createState() => PlaylistUl();
}

class PlaylistUl extends State {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  List<Playlist> l = new List<Playlist>();

  routePlaylistSong(BuildContext context, Playlist pl) async {
    print("Apro playlist: " + pl.id.toString());
    //TODO: Aprire playlist appena creata!
    List<Song> songs = await DBProvider.db.getAllPlaylistSongs(pl.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongUlStateless(songs, pl.title)),
    );
  }

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
      body: buildList(context),
      floatingActionButton: FloatingActionButton(
          tooltip: 'Add playlist',
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      CreatePlaylistStatefull(title: 'Flutter Demo Home Page')),
              //MaterialPageRoute(builder: (context) => Creat(title: 'Flutter Demo Home Page')),
            );
          }),
    );
  }

  Widget _buildPlaylistRow(BuildContext context, Playlist pair) {
    return ListTile(
      leading: const Icon(Icons.album),
      title: Text(
        pair.title,
        style: _biggerFont,
      ),
      onTap: () {
        routePlaylistSong(context, pair);
      },
      onLongPress: () {

      },
    );
  }

  Widget buildList(BuildContext context) {
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
              return _buildPlaylistRow(context, s);
            } else {
              //TODO: Statement unreachable!!!!
              return null;
            }
          });
    }
  }
}
