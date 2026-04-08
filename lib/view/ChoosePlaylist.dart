import 'package:flutter/material.dart';
import '../model/Playlist.dart';
import '../model/Song.dart';
import '../Database.dart';
import '../controller/AppLocalizations.dart';

class ChoosePlaylistStateful extends StatefulWidget {
  const ChoosePlaylistStateful({Key? key, this.title, required this.song})
      : super(key: key);
  final String? title;
  final Song song;

  @override
  ChoosePlaylist createState() => ChoosePlaylist(song: song);
}

class ChoosePlaylist extends State<ChoosePlaylistStateful> {
  final Song song;
  final _biggerFont = const TextStyle(fontSize: 18.0);
  List<Playlist> l = [];

  ChoosePlaylist({required this.song});

  @override
  void initState() {
    super.initState();
    _updateList();
  }

  Future<void> _updateList() async {
    if (l.isEmpty) {
      final list = await DBProvider.db.getAllPlaylist();
      if (mounted) setState(() => l = list);
    }
  }

  Future<void> _addSong(BuildContext context, Playlist pl) async {
    await DBProvider.db.newSongPlaylist(pl, song);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).choose_playlist),
      ),
      body: _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    if (l.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).no_playlist));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: l.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) => _buildRow(context, l[index]),
    );
  }

  Widget _buildRow(BuildContext context, Playlist pair) {
    return ListTile(
      leading: const Icon(Icons.album),
      title: Text(pair.title, style: _biggerFont),
      subtitle: Text(
        '${pair.songCount} ${pair.songCount == 1 ? AppLocalizations.of(context).song : AppLocalizations.of(context).songs}',
      ),
      onTap: () => _addSong(context, pair),
    );
  }
}
