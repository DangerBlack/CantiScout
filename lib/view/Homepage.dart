import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'SongUl.dart';
import '../model/Chartset.dart';


import '../model/SongList.dart';
import '../FirstRoute.dart';

class Homepage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SongUlStateful(title: 'Flutter Demo Home Page')),
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
                      title: Text('Playlist'),
                      subtitle: Text('Tutte le playlist'),
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