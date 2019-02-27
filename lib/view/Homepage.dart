import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'SongUl.dart';
import 'SongUlStateless.dart';
import 'PlaylistUl.dart';
import '../model/Song.dart';
import '../controller/Updater.dart';
import '../Database.dart';



import '../model/SongList.dart';
import '../FirstRoute.dart';

class Homepage extends StatelessWidget {

  updateList() async {
    SongList lg = await Updater.updateSongs();
    if(lg.list.isNotEmpty){
      print("Aggiornata!");
    }else{
      print("Up to date");
    }
  }

  routeSongs(BuildContext context) async{
    List<Song> songs = await DBProvider.db.getAllSongs();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongUlStateless(songs)),
      //MaterialPageRoute(builder: (context) => SongUlStateful(title: 'Flutter Demo Home Page')),
    );
  }
  @override
  Widget build(BuildContext context) {
    updateList();
    return Scaffold(
        appBar: AppBar(
          title: Text('Canti Scout'),
        ),
        body: Center(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                        leading: Icon(Icons.album),
                        title: Text('Canzoniere'),
                        subtitle: Text('Ascolta tutte le canzoni'),
                        onTap: (){
                          routeSongs(context);
                          /*Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SongUlStateful(title: 'Flutter Demo Home Page')),
                          );*/
                        }
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.album),
                      title: Text('Playlist'),
                      subtitle: Text('Tutte le playlist'),
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PlaylistUlStateful(title: 'Flutter Demo Home Page')),
                          );
                        }
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const ListTile(
                      leading: Icon(Icons.album),
                      title: Text('Altro'),
                      subtitle: Text('Altro...'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}