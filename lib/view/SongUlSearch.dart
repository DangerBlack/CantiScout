import 'package:flutter/material.dart';
import 'SongUl.dart';
import '../Database.dart';
import '../model/Song.dart';


class SongUlSearchStateful extends StatefulWidget {
  SongUlSearchStateful({Key key, this.title, this.search, this.state}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String search;
  final SongUlSearch state;

  /*@override
  SongUlSearch createState() {
    //state = SongUlSearch(search);
    return
  }*/


  @override
  SongUlSearch createState() => state;



}

class SongUlSearch extends SongUl {
  String _search;

  SongUlSearch(this._search) : super() {
    leadingIcon = Icons.music_note;
    //updateList();
  }

  @override
  void initState() {
    super.initState();
    updateList();
  }
  /*SongUlSearch.fromSearch(this.search):super(){
    updateList();
  }*/

  updateListS(String search) async {
    print("Aggiorno lista!");
    List<Song> lg = await DBProvider.db.getSongs(search);
    if(l != null && mounted) {
      setState(() {
        l.list = lg;
      });
    }
  }

  //TODO: Questo metodo va in errore perchè viene chiamata la setState nel costruttore!!!!
  updateList() async {
    if (l.list.isEmpty) {
      List<Song> lg = await DBProvider.db.getSongs(_search);
      setState(() {
        l.list = lg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //updateList();
    return buildList();
  }

  get search    => _search;
  set search(v) {
    _search = v;
    updateListS(_search);
    print("observed_field changed");
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    super.l = null;
  }
}