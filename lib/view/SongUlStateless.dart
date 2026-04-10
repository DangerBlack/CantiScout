import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/CustomSearchDelegate.dart';
import '../controller/Utils.dart';
import '../model/Constants.dart';
import '../model/Song.dart';
import '../view/CreateSong.dart';
import '../view/SongText.dart';

class SongUlStateless extends StatefulWidget {
  final String title;
  final ValueNotifier<int>? reloadTrigger;

  // The songs parameter is kept for API compatibility but ignored — we always
  // load fresh from DB so the list reflects newly created/imported songs.
  const SongUlStateless(List<Song> _, this.title,
      {Key? key, this.reloadTrigger})
      : super(key: key);

  @override
  State<SongUlStateless> createState() => _SongUlStatelessState();
}

class _SongUlStatelessState extends State<SongUlStateless> {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    widget.reloadTrigger?.addListener(_loadSongs);
    _loadSongs();
  }

  @override
  void dispose() {
    widget.reloadTrigger?.removeListener(_loadSongs);
    super.dispose();
  }

  Future<void> _loadSongs() async {
    final list = await DBProvider.db.getAllSongs();
    if (mounted) setState(() => _songs = list);
  }

  // ── FAB bottom sheet ────────────────────────────────────────────────────────

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppLocalizations.of(context).create_song),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('Incolla ChordPro'),
              onTap: () {
                Navigator.pop(ctx);
                _showPasteDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text('Importa da file (.cho / .chopro)'),
              onTap: () {
                Navigator.pop(ctx);
                _importFromFile(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Create from scratch ─────────────────────────────────────────────────────

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).create_dialog_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).create_dialog_body),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).create_dialog_body_sample,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${AppLocalizations.of(context).create_dialog_body_more} '),
                    const Text(
                      'ChordPro',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                onPressed: () => Utils.launchURL(Constants.urlChordPro),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                  AppLocalizations.of(context).dialog_confirm.toUpperCase()),
              onPressed: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (context) => CreateSongStatefull(
                      title: AppLocalizations.of(context).create_song,
                    ),
                  ),
                ).then((_) => _loadSongs());
              },
            ),
          ],
        );
      },
    );
  }

  // ── Paste ChordPro ──────────────────────────────────────────────────────────

  void _showPasteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Incolla ChordPro'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText:
                  '{title: Nome canzone}\n{author: Autore}\n\n[C]Testo...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text;
              Navigator.pop(ctx);
              await _importChordPro(context, text);
            },
            child: const Text('IMPORTA'),
          ),
        ],
      ),
    );
  }

  // ── Import from file ────────────────────────────────────────────────────────

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final lower = path.toLowerCase();
      if (!lower.endsWith('.chopro') &&
          !lower.endsWith('.cho') &&
          !lower.endsWith('.txt')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Seleziona un file .chopro, .cho o .txt')),
        );
        return;
      }
      final text = await File(path).readAsString();
      if (!mounted) return;
      await _importChordPro(context, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore importazione: $e')),
      );
    }
  }

  // ── Core import logic ───────────────────────────────────────────────────────

  Future<void> _importChordPro(BuildContext context, String text) async {
    if (text.trim().isEmpty) return;

    final song = Utils.parseSongFromChordPro(text);
    final existing =
        await DBProvider.db.getSongByTitleAuthor(song.title, song.author);
    if (!mounted) return;

    if (existing != null) {
      await _showConflictDialog(context, song, existing);
    } else {
      await DBProvider.db.newSong(song);
      await _loadSongs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${song.title}" importata!')),
        );
      }
    }
  }

  Future<void> _showConflictDialog(
      BuildContext context, Song newSong, Song existingSong) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Canzone già esistente'),
        content: Text('"${existingSong.title}"'
            '${existingSong.author != null ? ' di ${existingSong.author}' : ''}'
            ' è già presente. Cosa vuoi fare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final copy = Song(
                id: newSong.id,
                title: '${newSong.title} (2)',
                author: newSong.author,
                time: newSong.time,
                body: newSong.body,
                status: newSong.status,
              );
              await DBProvider.db.newSong(copy);
              await _loadSongs();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${copy.title}" importata!')),
                );
              }
            },
            child: const Text('MANTIENI ENTRAMBE'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              existingSong.body = newSong.body;
              existingSong.author = newSong.author;
              await DBProvider.db.updateSong(existingSong);
              await _loadSongs();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('"${existingSong.title}" aggiornata!')),
                );
              }
            },
            child: const Text('SOSTITUISCI'),
          ),
        ],
      ),
    );
  }

  // ── List UI ─────────────────────────────────────────────────────────────────

  Widget _buildSongRow(BuildContext context, Song song) {
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(song.title, style: _biggerFont),
      subtitle: Text(song.author ?? ''),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SongText(song: song)),
        ).then((_) => _loadSongs());
      },
      onLongPress: () => _confirmDelete(context, song),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).ask_remove),
        content: Text(
          'Vuoi eliminare definitivamente "${song.title}"?'
          '\nVerrà rimossa da tutte le playlist.',
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context).undo,
                style: const TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: Text(AppLocalizations.of(context).ok,
                style: const TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DBProvider.db.deleteSong(song.id);
      _loadSongs();
    }
  }

  Widget _buildList(BuildContext context) {
    if (_songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Nessuna canzone.\nPremi + per aggiungerne una.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _songs.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) => _buildSongRow(context, _songs[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
      body: _buildList(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        tooltip: AppLocalizations.of(context).add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
