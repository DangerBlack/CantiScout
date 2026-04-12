import 'package:flutter/material.dart';

import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/ChopackController.dart';
import '../controller/PdfController.dart';
import '../model/Playlist.dart';
import '../model/Song.dart';
import '../view/BleSendView.dart';
import '../view/QrSendView.dart';
import '../view/SongText.dart';

class SongUlPlaylistStateless extends StatefulWidget {
  final List<Song> initialSongs;
  final String title;
  final int playlistId;

  const SongUlPlaylistStateless(this.initialSongs, this.title, this.playlistId,
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

  void _showShareSheet(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(loc.export_pdf),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final songs = await DBProvider.db
                      .getAllPlaylistSongs(widget.playlistId);
                  await PdfController.exportPlaylistToPdf(songs, widget.title);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore export PDF: $e')));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: Text(loc.export_chopack),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final songs = await DBProvider.db
                      .getAllPlaylistSongs(widget.playlistId);
                  final playlist = Playlist(
                    id: widget.playlistId,
                    title: widget.title,
                    time: DateTime.now().toIso8601String(),
                  );
                  await ChopackController.exportPack(songs, widget.title,
                      playlist: playlist);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore esportazione: $e')));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('Invia via Bluetooth'),
              onTap: () {
                Navigator.pop(ctx);
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
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: Text(loc.share_via_qr_menu),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrSendView(
                      playlistId: widget.playlistId,
                      playlistName: widget.title,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: loc.share,
            onPressed: () => _showShareSheet(context),
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
