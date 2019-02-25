import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../model/SongList.dart';
import '../FirstRoute.dart';
import '../view/SongText.dart';
import '../controller/Updater.dart';
import '../controller/CustomSearchDelegate.dart';
import '../Database.dart';

class SongUlStateful extends StatefulWidget {
  SongUlStateful({Key key, this.title}) : super(key: key);


  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  SongUl createState() => SongUl();
//_MyHomePageState createState() => _MyHomePageState();
}

class SongUl extends State {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final _suggestions = <String>[];
  SongList l = new SongList();
  SongUl():super(){
    updateList();
  }

  updateList() async {
    //TODO: lista
    if(l.list.isEmpty) {
      List<Song> lg = await DBProvider.db.getAllSongs();
      setState(() {
        l.list = lg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //updateList();
    return Scaffold(
      appBar: AppBar(
        title: Text("Elenco canzoni"),
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
      body: buildList(),
    );
  }

  Widget _buildSongRow(Song pair) {
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

  Widget buildList() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: l.list.length * 2,
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return Divider();
          /*2*/
          int index = i ~/ 2;
          if (index <= l.list.length) {
            var s = l.get(index);
            return _buildSongRow(s);
          } else {
            //TODO: Statement unreachable!!!!
            return null;
          }
        });
  }
}


