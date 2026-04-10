import 'package:flutter/material.dart';

import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/ChopackController.dart';
import '../controller/PdfController.dart';
import '../model/Playlist.dart';
import '../model/Song.dart';
import '../view/BleSendView.dart';
import '../view/SongText.dart';

class SongUlPlaylistStateless extends StatefulWidget {
  final List<Song> initialSongs;
  final String title;
  final int playlistId;

  const SongUlPlaylistStateless(
      this.initialSongs, this.title, this.playlistId,
      {Key? key})
      : super(key: key);

  @override
  State<SongUlPlaylistStateless> createState() =>
      _SongUlPlaylistStatelessState();
}

class _SongUlPlaylistStatelessState extends State<SongUlPlaylistStateless> {
  late List<Song> _songs;

  @override
  void initState() {
    super.initState();
    _songs = List.from(widget.initialSongs);
  }

Future<void> _confirmRemove(
      BuildContext context, Song song, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).ask_remove),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)
                .do_you_want_to_remove
                .replaceFirst(RegExp('###'), song.title)),
            Text(widget.title),
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
      await DBProvider.db.removeSongPlaylistRaw(widget.playlistId, song.id);
      if (mounted) setState(() => _songs.removeAt(index));
    }
  }

  Widget _buildRow(BuildContext context, Song song, int index) {
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(song.title, style: const TextStyle(fontSize: 18.0)),
      subtitle: Text(song.author ?? ''),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SongText(song: song)),
        );
      },
      onLongPress: () => _confirmRemove(context, song, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Esporta PDF',
            onPressed: () async {
              try {
                final songs =
                    await DBProvider.db.getAllPlaylistSongs(widget.playlistId);
                await PdfController.exportPlaylistToPdf(songs, widget.title);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Errore export PDF: $e')));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Esporta playlist (.chopack)',
            onPressed: () async {
              try {
                final songs = await DBProvider.db.getAllPlaylistSongs(widget.playlistId);
                final playlist = Playlist(
                  id: widget.playlistId,
                  title: widget.title,
                  time: DateTime.now().toIso8601String(),
                );
                await ChopackController.exportPack(songs, widget.title, playlist: playlist);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Errore esportazione: $e')));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth),
            tooltip: 'Invia via Bluetooth',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BleSendView(
                    playlistId: widget.playlistId,
                    playlistName: widget.title,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _songs.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) =>
            _buildRow(context, _songs[index], index),
      ),
    );
  }
}
