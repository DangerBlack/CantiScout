import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../model/SongList.dart';
import '../FirstRoute.dart';
import '../view/SongText.dart';
import '../controller/Updater.dart';
import '../controller/CustomSearchDelegate.dart';
import '../Database.dart';


class SongUlStateless extends StatelessWidget {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  String title = "Elenco canzoni";
  SongList l = new SongList();

  SongUlStateless(List<Song> songs,String title):super(){
    this.title = title;
    updateList(songs);
  }
  updateList(List<Song> songs){
    l.list = songs;
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
    );
  }

  Widget _buildSongRow(BuildContext context,Song pair) {
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
        });
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
            return _buildSongRow(context,s);
          } else {
            //TODO: Statement unreachable!!!!
            return null;
          }
        });
  }
}