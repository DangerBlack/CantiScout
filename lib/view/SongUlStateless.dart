import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/ChopackController.dart';
import '../controller/ConflictDialog.dart';
import '../controller/CustomSearchDelegate.dart';
import '../controller/IncomingFileService.dart';
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
  StreamSubscription<String>? _fileSubscription;

  @override
  void initState() {
    super.initState();
    widget.reloadTrigger?.addListener(_loadSongs);
    _loadSongs();
    _fileSubscription =
        IncomingFileService.instance.fileStream.listen(_ingestPath);
  }

  @override
  void dispose() {
    _fileSubscription?.cancel();
    widget.reloadTrigger?.removeListener(_loadSongs);
    super.dispose();
  }

  Future<void> _loadSongs() async {
    final list = await DBProvider.db.getAllSongs();
    if (mounted) setState(() => _songs = list);
  }

  // ── OS file-open ingestion ──────────────────────────────────────────────────

  Future<void> _ingestPath(String path) async {
    if (!mounted) return;
    final lower = path.toLowerCase();
    if (lower.endsWith('.chopack')) {
      await _ingestChopack(path);
    } else if (lower.endsWith('.cho') ||
        lower.endsWith('.chopro') ||
        lower.endsWith('.txt')) {
      try {
        final text = await File(path).readAsString();
        if (!mounted) return;
        await _importChordPro(context, text);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context).import_error(e.toString()))));
      }
    }
  }

  Future<void> _ingestChopack(String path) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
                child: Text(AppLocalizations.of(context).reading_file)),
          ]),
        ),
      ),
    );

    try {
      final (incoming, tagsMap, importedPlaylists) =
          await ChopackController.importPack(path);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (incoming.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).no_songs_in_file)));
        return;
      }

      final newSongs = <Song>[];
      final conflicts = <Song>[];
      for (final song in incoming) {
        final existing =
            await DBProvider.db.getSongByTitleAuthor(song.title, song.author);
        (existing != null ? conflicts : newSongs).add(song);
      }

      ConflictPolicy policy = ConflictPolicy.skip;
      if (conflicts.isNotEmpty && mounted) {
        final chosen = await showBulkConflictDialog(
          context,
          conflictCount: conflicts.length,
          newCount: newSongs.length,
        );
        if (chosen != null) policy = chosen;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                  child:
                      Text(AppLocalizations.of(context).importing_in_progress)),
            ]),
          ),
        ),
      );

      final idMap = <String, String>{};
      int imported = 0;

      for (final song in newSongs) {
        await DBProvider.db.newSong(song);
        if (tagsMap.containsKey(song.id)) {
          await ChopackController.saveTags(song.id, tagsMap[song.id]!);
        }
        idMap[song.id] = song.id;
        imported++;
      }

      for (final song in conflicts) {
        switch (policy) {
          case ConflictPolicy.skip:
            break;
          case ConflictPolicy.keepBoth:
            final saved = Song.create(
                title: '${song.title} (2)',
                author: song.author,
                body: song.body);
            await DBProvider.db.newSong(saved);
            if (tagsMap.containsKey(song.id)) {
              await ChopackController.saveTags(saved.id, tagsMap[song.id]!);
            }
            idMap[song.id] = saved.id;
            imported++;
          case ConflictPolicy.replace:
            final existing = await DBProvider.db
                .getSongByTitleAuthor(song.title, song.author);
            if (existing != null) {
              existing.body = song.body;
              existing.author = song.author;
              await DBProvider.db.updateSong(existing);
              if (tagsMap.containsKey(song.id)) {
                await ChopackController.saveTags(
                    existing.id, tagsMap[song.id]!);
              }
              idMap[song.id] = existing.id;
              imported++;
            }
        }
      }

      if (importedPlaylists.isNotEmpty) {
        await ChopackController.savePlaylists(importedPlaylists, idMap);
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _loadSongs();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).songs_imported(imported))));
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context).import_error(e.toString()))));
      }
    }
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
              leading: const Icon(Icons.file_open),
              title: Text(AppLocalizations.of(context).import_from_file),
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

  // ── Import from file ────────────────────────────────────────────────────────

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
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
          SnackBar(content: Text(AppLocalizations.of(context).select_chordpro_file)),
        );
        return;
      }
      final text = await File(path).readAsString();
      if (!mounted) return;
      await _importChordPro(context, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).import_error(e.toString()))),
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
      final policy = await showSingleConflictDialog(context, song);
      if (!mounted || policy == null) return;
      switch (policy) {
        case ConflictPolicy.keepBoth:
          final copy = Song(
            id: song.id,
            title: '${song.title} (2)',
            author: song.author,
            time: song.time,
            body: song.body,
            status: song.status,
          );
          await DBProvider.db.newSong(copy);
          await _loadSongs();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).song_imported(copy.title))));
          }
        case ConflictPolicy.replace:
          existing.body = song.body;
          existing.author = song.author;
          await DBProvider.db.updateSong(existing);
          await _loadSongs();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).song_updated(existing.title))));
          }
        case ConflictPolicy.skip:
          break;
      }
    } else {
      await DBProvider.db.newSong(song);
      await _loadSongs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).song_imported(song.title))),
        );
      }
    }
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
        content: Text(AppLocalizations.of(context).confirm_delete_song(song.title)),
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
                AppLocalizations.of(context).no_songs_hint,
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
