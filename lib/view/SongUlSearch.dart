import 'package:flutter/material.dart';

import '../Database.dart';
import '../model/Song.dart';
import '../view/SongText.dart';

class SongUlSearchStateful extends StatefulWidget {
  final String search;

  const SongUlSearchStateful({Key? key, required this.search})
      : super(key: key);

  @override
  State<SongUlSearchStateful> createState() => _SongUlSearchState();
}

class _SongUlSearchState extends State<SongUlSearchStateful> {
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs(widget.search);
  }

  @override
  void didUpdateWidget(SongUlSearchStateful oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search != widget.search) {
      _loadSongs(widget.search);
    }
  }

  Future<void> _loadSongs(String search) async {
    final list = await DBProvider.db.getSongs(search);
    if (mounted) setState(() => _songs = list);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _songs.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final song = _songs[index];
        return ListTile(
          leading: const Icon(Icons.music_note),
          title: Text(song.title, style: const TextStyle(fontSize: 18.0)),
          subtitle: Text(song.author ?? ''),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SongText(song: song)),
          ),
        );
      },
    );
  }
}
