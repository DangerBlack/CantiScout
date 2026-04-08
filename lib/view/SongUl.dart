import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../model/SongList.dart';
import '../view/SongText.dart';
import '../controller/CustomSearchDelegate.dart';
import '../Database.dart';
import '../controller/AppLocalizations.dart';

class SongUlStateful extends StatefulWidget {
  const SongUlStateful({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  SongUl createState() => SongUl();
}

class SongUl extends State<SongUlStateful> {
  IconData leadingIcon = Icons.album;
  final _biggerFont = const TextStyle(fontSize: 18.0);
  SongList l = SongList();

  @override
  void initState() {
    super.initState();
    updateList();
  }

  Future<void> updateList() async {
    final List<Song> lg = await DBProvider.db.getAllSongs();
    if (mounted) {
      setState(() => l.list = lg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).songs_list),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
      leading: Icon(leadingIcon),
      title: Text(pair.title, style: _biggerFont),
      subtitle: Text(pair.author ?? ''),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SongText(song: pair)),
        );
      },
    );
  }

  Widget buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: l.list.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) => _buildSongRow(l.list[index]),
    );
  }
}
