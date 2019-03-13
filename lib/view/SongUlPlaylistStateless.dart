import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:convert/convert.dart';
import 'package:lzma/lzma.dart';
import '../model/Song.dart';
import '../model/Playlist.dart';
import '../model/Constants.dart';
import '../view/SongUlStateless.dart';
import '../view/SongText.dart';
import '../Database.dart';

import '../controller/CustomSearchDelegate.dart';


class SongUlPlaylistStateless extends SongUlStateless {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  Playlist playlist;


  SongUlPlaylistStateless(List<Song> songs,title, user, int plId):super(songs,title,user){
    //this.title = title;
    //this.user = user;
    this.l.list = songs;
    this.playlist = new Playlist();
    this.playlist.id = plId;
    this.playlist.title = title;
    //updateList(songs);
  }

  String _generateSharableList(){
    List<int> g = new List<int>();
    String s ="";
    for( var f in this.l.list){
      g.add(f.id);
    }

    print(g);
    print(hex.encode(g));
    s+=Uri.encodeFull(this.title)+"-"+hex.encode(g);
    s = Constants.tokenApi+Constants.tokenPlaylist+s;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    //updateList();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              /*final input = <int>[1,2,3,4,5,8,9,5,2,5,4,5,6,4,8,7,81,6,2,1,54,8,1,2,3,4,5,8,9,5,2,5,4,5,6,4,8,7,81,6,2,1,54,8,1,2,3,4,5,8,9,5,2,5,4,5,6,4,8,7,81,6,2,1,54,8];
              final compressed = lzma.encode(input);
              print(compressed);
              final decompressed = lzma.decode(compressed);
              print(decompressed);*/

              String url =_generateSharableList();
              Share.share('Guada questa playlist: ' + url);
            },
          ),
        ],
      ),
      body: buildList(context),
    );
  }

  @override
  Widget buildSongRow(BuildContext context,Song pair,int index) {
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(
        pair.title,
        style: _biggerFont,
      ),
      subtitle: Text(
        pair.author,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SongText(song: pair)),
        );
      },
      onLongPress: (){
        print("wow2!");
        _neverSatisfied(context,pair,index);
      },
    );
  }

  Future<void> _neverSatisfied(BuildContext context,Song song, int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rimuovere?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Vuoi rimuovere "'+song.title+'" dalla playlist:'),
                Text(title),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(
                  'ANNULLA',
                  style: TextStyle(color:Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                l.list.removeAt(index);
                _deleteSong(context,song);

              },
            ),
          ],
        );
      },
    );
  }
  _deleteSong(BuildContext context, Song song) async {
    print("PL ID: "+playlist.id.toString());
    print("SONG ID: "+song.id.toString());
    await DBProvider.db.removeSongPlaylistRaw(playlist.id,song.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongUlPlaylistStateless(l.list, title, user, playlist.id)),
    );
  }

}