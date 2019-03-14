import 'package:flutter/material.dart';
import '../model/Playlist.dart';
import '../model/Song.dart';
import '../model/User.dart';

import 'PlaylistUl.dart';
import '../Database.dart';
import '../controller/AppLocalizations.dart';

class ChoosePlaylistStateful extends StatefulWidget {
  ChoosePlaylistStateful({Key key, this.title, this.song}) : super(key: key);
  final String title;
  final Song song;

  @override
  ChoosePlaylist createState() => ChoosePlaylist(song:this.song);
}

class ChoosePlaylist extends PlaylistUl {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final Song song;
  ChoosePlaylist({this.song}) : super(new User("nope","nope"));
  addSong(BuildContext context,Playlist pl) async{
    print(pl.title);
    print(pl.id);
    var t = await DBProvider.db.newSongPlaylist(pl,song);
    print("Aggiunto?");
    print(t);
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    //updateList();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).choose_playlist),
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
    );
  }

  Widget _buildPlaylistRow(BuildContext context,Playlist pair) {
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
          addSong(context,pair);
        });
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
              return _buildPlaylistRow(context,s);
            } else {
              //TODO: Statement unreachable!!!!
              return null;
            }
          });
    }
  }
}