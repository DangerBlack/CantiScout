import 'package:flutter/material.dart';
import '../Database.dart';
import '../model/Song.dart';
import '../model/Playlist.dart';
import '../model/User.dart';
import 'Createplaylist.dart';
import 'SongULStateless.dart';
import 'SongUlPlaylistStateless.dart';

import '../controller/AppLocalizations.dart';

class PlaylistUlStateful extends StatefulWidget {
  final User user;
  PlaylistUlStateful({Key key, this.title, this.user}) : super(key: key);
  final String title;

  @override
  PlaylistUl createState() => PlaylistUl(user);
}

class PlaylistUl extends State {
  User user;

  final _biggerFont = const TextStyle(fontSize: 18.0);
  List<Playlist> l = new List<Playlist>();

  routePlaylistSong(BuildContext context, Playlist pl) async {
    print("Apro playlist: " + pl.id.toString());
    //TODO: Aprire playlist appena creata!
    List<Song> songs = await DBProvider.db.getAllPlaylistSongs(pl.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongUlPlaylistStateless(songs, pl.title, user, pl.id)),
    );
  }

  PlaylistUl(User user) : super() {
    this.user = user;
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
        title: Text(AppLocalizations.of(context).playlist_list),
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
          tooltip: AppLocalizations.of(context).add_playlist,
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      CreatePlaylistStatefull(title: 'Flutter Demo Home Page', user: user)),
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
      subtitle: Text(
        pair.songCount.toString()+" "+(pair.songCount>1||pair.songCount==0 ?AppLocalizations.of(context).songs:AppLocalizations.of(context).song),
      ),
      onTap: () {
        routePlaylistSong(context, pair);
      },
      onLongPress: () {
        _neverSatisfied(context,pair);
      },
    );
  }

  Widget buildList(BuildContext context) {
    if (l.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).no_playlist),
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


  Future<void> _neverSatisfied(BuildContext context,Playlist pl) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).ask_remove),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context).ask_remove_desc),
                Text(pl.title),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(
                AppLocalizations.of(context).undo,
                style: TextStyle(color:Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(AppLocalizations.of(context).ok),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePlaylist(context,pl);

              },
            ),
          ],
        );
      },
    );
  }
  _deletePlaylist(BuildContext context, Playlist pl) async {
    print("PL ID: "+pl.id.toString());
    await DBProvider.db.removePlaylistRaw(pl.id);
    List<Playlist> lg = await DBProvider.db.getAllPlaylist();
    setState(() {
      l = lg;
    });
  }
}
