import 'package:flutter/material.dart';
import '../Database.dart';
import '../model/Song.dart';
import '../model/Playlist.dart';
import 'CreatePlaylist.dart';
import 'SongUlPlaylistStateless.dart';
import '../controller/AppLocalizations.dart';

class PlaylistUlStateful extends StatefulWidget {
  const PlaylistUlStateful({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  PlaylistUl createState() => PlaylistUl();
}

class PlaylistUl extends State<PlaylistUlStateful> {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  List<Playlist> l = [];

  @override
  void initState() {
    super.initState();
    _updateList();
  }

  Future<void> _updateList() async {
    final list = await DBProvider.db.getAllPlaylist();
    if (mounted) setState(() => l = list);
  }

  Future<void> _routePlaylistSong(
      BuildContext context, Playlist pl) async {
    final List<Song> songs =
        await DBProvider.db.getAllPlaylistSongs(pl.id);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SongUlPlaylistStateless(songs, pl.title, pl.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).playlist_list),
      ),
      body: _buildList(context),
      floatingActionButton: FloatingActionButton(
        tooltip: AppLocalizations.of(context).add_playlist,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const CreatePlaylistStatefull(title: 'New Playlist'),
            ),
          );
          _updateList();
        },
      ),
    );
  }

  Widget _buildPlaylistRow(BuildContext context, Playlist pair) {
    return ListTile(
      leading: const Icon(Icons.album),
      title: Text(pair.title, style: _biggerFont),
      subtitle: Text(
        '${pair.songCount} ${pair.songCount == 1 ? AppLocalizations.of(context).song : AppLocalizations.of(context).songs}',
      ),
      onTap: () => _routePlaylistSong(context, pair),
      onLongPress: () => _confirmDelete(context, pair),
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
      itemBuilder: (context, index) =>
          _buildPlaylistRow(context, l[index]),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Playlist pl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).ask_remove),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).ask_remove_desc),
            Text(pl.title),
          ],
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context).undo,
                style: const TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: Text(AppLocalizations.of(context).ok),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DBProvider.db.removePlaylistRaw(pl.id);
      _updateList();
    }
  }
}
