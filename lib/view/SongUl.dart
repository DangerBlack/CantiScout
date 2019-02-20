import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../model/SongList.dart';
import '../FirstRoute.dart';
import '../view/SongText.dart';


class SongUl extends State {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final _suggestions = <String>[];
  SongList l = new SongList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Elenco canzoni"),
      ),
      body:  _buildList(),
    );
  }

  Widget _buildSongRow(Song pair) {
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(
        pair.title,
        style: _biggerFont,
      ),
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SongText(song:pair)),
        );
      }
    );
  }
  Widget _buildList() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: l.list.length*2,
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return Divider(); /*2*/
          int index = i ~/ 2;
          if (index <= l.list.length) {
            var s = l.get(index);
            return _buildSongRow(s);
          }else{
            //TODO: Statement unreachable!!!!
            return null;
          }
        });
  }

}