import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:lzma/lzma.dart';
import '../model/Song.dart';
import '../model/Constants.dart';
import '../view/SongUlStateless.dart';
import 'package:convert/convert.dart';

import '../controller/CustomSearchDelegate.dart';


class SongUlPlaylistStateless extends SongUlStateless {

  SongUlPlaylistStateless(List<Song> songs,title, user):super(songs,title,user){
    //this.title = title;
    //this.user = user;
    this.l.list = songs;
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
    s+=user.name+"-"+hex.encode(g);
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

}