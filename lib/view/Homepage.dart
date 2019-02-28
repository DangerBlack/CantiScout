import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';

import 'SongUl.dart';
import 'SongUlStateless.dart';
import 'PlaylistUl.dart';
import 'Settings.dart';
import '../model/Song.dart';
import '../model/DrawerItem.dart';
import '../controller/Updater.dart';
import '../Database.dart';

import '../model/SongList.dart';
import '../model/Constants.dart';
import '../FirstRoute.dart';

class Homepage extends StatelessWidget {
  final drawerItems = [
    new DrawerItem("Sincronizza", Icons.sync, null),
    new DrawerItem("Account", Icons.account_circle, null),
    new Divider(),
    new DrawerItem("Impostazioni", Icons.settings, (context){
      Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => SettingsStateful(title:"Settings")),
      );
    }),
    new DrawerItem("Guida", Icons.help_outline, null),
  ];

  generateMd5(String data) {
    var content = new Utf8Encoder().convert(data);
    var md5 = crypto.md5;
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  updateList() async {
    SongList lg = await Updater.updateSongs();
    if (lg.list.isNotEmpty) {
      print("Aggiornata!");
    } else {
      print("Up to date");
    }
  }

  routeSongs(BuildContext context) async {
    List<Song> songs = await DBProvider.db.getAllSongs();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SongUlStateless(songs, "Elenco canzoni")),
      //MaterialPageRoute(builder: (context) => SongUlStateful(title: 'Flutter Demo Home Page')),
    );
  }
  _onSelectItem(BuildContext context,int index){
    DrawerItem d = drawerItems[index];
    if(d.action != null) {
      d.action(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    updateList();

    var drawerOptions = <Widget>[];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      if (d is DrawerItem) {
        drawerOptions.add(new ListTile(
          leading: new Icon(d.icon),
          title: new Text(d.title),
//            selected: i == _selectedDrawerIndex,
            onTap: () => _onSelectItem(context, i),
        ));
      } else {
        drawerOptions.add(d);
      }
    }

    return Scaffold(
      drawer: new Drawer(
        child: new Column(
          children: <Widget>[
            new UserAccountsDrawerHeader(
                accountName: new Text("John Doe"),
                accountEmail: new Text("utente@utente.it"),
                currentAccountPicture: new CircleAvatar(
                  backgroundImage: NetworkImage(Constants.gravatarUrl+generateMd5("danger.recheng@hotmail.it")),
                )
            ),
            new Column(children: drawerOptions)
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('Canti Scout'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(20.0),
          ),
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                    leading: Icon(Icons.book),
                    title: Text('Canzoniere'),
                    subtitle: Text('Ascolta tutte le canzoni'),
                    onTap: () {
                      routeSongs(context);
                      /*Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SongUlStateful(title: 'Flutter Demo Home Page')),
                          );*/
                    }),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PlaylistUlStateful(
                                title: 'Flutter Demo Home Page')),
                      );
                    }),
              ],
            ),
          ),
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Altro'),
                  subtitle: Text('Altro...'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
