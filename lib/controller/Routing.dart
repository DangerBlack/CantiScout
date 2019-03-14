import 'dart:async';
import 'package:canti_scout/model/Playlist.dart';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:convert/convert.dart';


import '../view/SongText.dart';
import '../view/SongUlPlaylistStateless.dart';
import '../model/User.dart';
import '../model/Song.dart';
import '../Database.dart';


class Routing{

  static _checkSongTextView(String initialLink, BuildContext context, User user) async{
    if(initialLink.contains("song.php?id=")) {
      String ids = initialLink.split("song.php?id=")[1];
      print(ids);
      int id = int.parse(ids);
      Song song = await DBProvider.db.getSong(id);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SongText(song: song)),
      );
    }
  }

  static _checkPlaylistView(String initialLink, BuildContext context, User user) async{
    if(initialLink.contains("playlist/")) {
      String pl = initialLink.split("playlist/")[1];
      String title = pl.split("-")[0];
      title = Uri.decodeFull(title);
      String plHash = pl.split("-")[1];
      List<int> list = hex.decode(plHash);

      //TODO verificare che non esista playlist con stesso nome!!!
      List<Playlist> playlists = await DBProvider.db.hasPlaylist(title);
      int idPl;
      if(playlists.isEmpty){
        idPl = await DBProvider.db.newPlaylist(title);
        print("Playlist: ");
        print(idPl);
        for(int id in list){
          await DBProvider.db.newSongPlaylistRaw(idPl,id);
        }
      }else{
        idPl = playlists[0].id;
      }
      List<Song> ls = await DBProvider.db.getAllPlaylistSongs(idPl);
      Navigator.push(
      context,
        MaterialPageRoute(builder: (context) => SongUlPlaylistStateless(ls,title,user,idPl)),
      );
    }
  }
  static Future<Null> checkRoutingLinks(BuildContext context,User user) async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      String initialLink = await getInitialLink();
      print("URL INIZIALE:");
      print(initialLink);
      // Parse the link and warn the user, if it is not correct,
      // but keep in mind it could be `null`.
      if(initialLink!=null) {
        _checkSongTextView(initialLink, context, user);
        _checkPlaylistView(initialLink, context, user);
      }

    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      // return?
    }
  }
}