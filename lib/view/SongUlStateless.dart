import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../model/SongList.dart';
import '../model/User.dart';
import '../view/SongText.dart';
import '../view/CreateSong.dart';
import '../controller/CustomSearchDelegate.dart';
import '../controller/AppLocalizations.dart';


class SongUlStateless extends StatelessWidget {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final User user;
  final String title;// = "Elenco canzoni";
  final SongList l = new SongList();

  SongUlStateless(List<Song> songs,this.title, this.user):super(){
    //this.title = title;
    //this.user = user;
    this.l.list = songs;
    //updateList(songs);
  }
  updateList(List<Song> songs){
    this.l.list = songs;
  }

  @override
  Widget build(BuildContext context) {
    //updateList();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: buildList(context),
      floatingActionButton: user.logged?FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateSongStatefull(title: AppLocalizations.of(context).create_song),
            ),
          );
        },
        tooltip: AppLocalizations.of(context).add,
        child: Icon(Icons.add),
      ):null,
    );
  }

  Widget buildSongRow(BuildContext context,Song pair, int index) {
    return ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(
          pair.title,
          style: _biggerFont,
        ),
        subtitle: Text(
          pair.author ?? "",
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SongText(song: pair)),
          );
        },
        onLongPress: (){
          print("wow!");
        },
    );
  }

  Widget buildList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: l.list.length * 2,
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return Divider();
          /*2*/
          int index = i ~/ 2;
          if (index <= l.list.length) {
            var s = l.get(index);
            return buildSongRow(context,s,index);
          } else {
            //TODO: Statement unreachable!!!!
            return null;
          }
        });
  }
}