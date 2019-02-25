import 'package:flutter/material.dart';
import 'SongUl.dart';
import '../Database.dart';
import '../model/Song.dart';

class SongUlSearchStateful extends StatefulWidget {
  SongUlSearchStateful({Key key, this.title, this.search}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String search;

  @override
  SongUlSearch createState() => SongUlSearch(search);
//_MyHomePageState createState() => _MyHomePageState();
}

class SongUlSearch extends SongUl{
  final String search;

  SongUlSearch(this.search): super(){
    updateList();
  }

  /*SongUlSearch.fromSearch(this.search):super(){
    updateList();
  }*/

  updateList() async {
    if(l.list.isEmpty) {
      List<Song> lg = await DBProvider.db.getSongs(search);
      setState(() {
        l.list = lg;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    //updateList();
    return  buildList();
  }
}