import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../Database.dart';
import '../model/Playlist.dart';
import '../model/Song.dart';
import 'Utils.dart';

/// Handles `.chopack` export and import.
///
/// A `.chopack` is a ZIP file containing:
///   - `metadata.json`  — all song metadata, tags, and playlists
///   - `{title}.chopro` — one ChordPro file per song (human-readable body)
class ChopackController {
  static const String _kMeta = 'metadata.json';

  // ── Export ──────────────────────────────────────────────────────────────────

  /// Build and share a `.chopack` for [songs].
  ///
  /// [packName] is used as the filename (no extension).
  /// [playlist] — when provided, only that playlist is embedded in the pack.
  ///              When omitted (full-library export), all playlists are included.
  static Future<void> exportPack(
    List<Song> songs,
    String packName, {
    Playlist? playlist,
  }) async {
    final archive = Archive();

    // Collect tags and build metadata entries
    final metaSongs = <Map<String, dynamic>>[];
    for (final song in songs) {
      final tags = await DBProvider.db.getTagsBySongId(song.id);
      final filename = _filename(song);
      metaSongs.add({
        'id': song.id,
        'title': song.title,
        'author': song.author ?? '',
        'time': song.time,
        'status': song.status,
        'tags': tags.map((t) => t.tag).toList(),
        'file': filename,
      });
      // Add the .chopro file
      final bodyBytes = utf8.encode(song.body);
      archive.addFile(ArchiveFile(filename, bodyBytes.length, bodyBytes));
    }

    // Build playlist entries
    final List<Map<String, dynamic>> playlistsMeta;
    if (playlist != null) {
      // Single playlist: reference the songs already in this pack
      playlistsMeta = [
        {
          'title': playlist.title,
          'songs': songs.map((s) => s.id).toList(),
        }
      ];
    } else {
      // Full library: include every playlist from the DB
      final allPlaylists = await DBProvider.db.getAllPlaylist();
      playlistsMeta = [];
      for (final pl in allPlaylists) {
        final plSongs = await DBProvider.db.getAllPlaylistSongs(pl.id);
        playlistsMeta.add({
          'title': pl.title,
          'songs': plSongs.map((s) => s.id).toList(),
        });
      }
    }

    // Add metadata.json
    final metaBytes = utf8.encode(jsonEncode({
      'version': 2,
      'exported': DateTime.now().toIso8601String(),
      'songs': metaSongs,
      'playlists': playlistsMeta,
    }));
    archive.addFile(ArchiveFile(_kMeta, metaBytes.length, metaBytes));

    // Write ZIP to temp file and share
    final zipBytes = ZipEncoder().encode(archive);
    final dir = await getTemporaryDirectory();
    final safeName = packName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final file = File('${dir.path}/$safeName.chopack');
    await file.writeAsBytes(zipBytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/octet-stream')],
      subject: packName,
    );
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  /// Parse a `.chopack` file at [path].
  ///
  /// Returns `(songs, tagsMap, playlists)` where:
  ///   - `tagsMap`   : original songId → tag strings
  ///   - `playlists` : list of (playlistTitle, [original songIds])
  ///
  /// Falls back to parsing `.chopro` files if `metadata.json` is absent.
  static Future<(List<Song>, Map<String, List<String>>, List<(String, List<String>)>)>
      importPack(String path) async {
    final zipBytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final metaFile = archive.findFile(_kMeta);
    if (metaFile != null) {
      return _importWithMeta(archive, metaFile);
    } else {
      final (songs, tags) = _importFallback(archive);
      return (songs, tags, <(String, List<String>)>[]);
    }
  }

  static (List<Song>, Map<String, List<String>>, List<(String, List<String>)>)
      _importWithMeta(Archive archive, ArchiveFile metaFile) {
    final meta =
        jsonDecode(utf8.decode(metaFile.content as List<int>)) as Map;
    final songs = <Song>[];
    final tagsMap = <String, List<String>>{};

    for (final entry in (meta['songs'] as List<dynamic>)) {
      final filename = entry['file'] as String;
      final bodyFile = archive.findFile(filename);
      final body = bodyFile != null
          ? utf8.decode(bodyFile.content as List<int>)
          : '';

      final id = entry['id']?.toString().isNotEmpty == true
          ? entry['id'].toString()
          : const Uuid().v4();
      songs.add(Song(
        id: id,
        title: entry['title']?.toString() ?? '',
        author: (entry['author'] as String?)?.isEmpty ?? true
            ? null
            : entry['author'] as String,
        time: entry['time']?.toString() ?? DateTime.now().toIso8601String(),
        body: body,
        status: (entry['status'] as num?)?.toInt() ?? 0,
      ));

      final tags = (entry['tags'] as List<dynamic>?)
          ?.map((t) => t.toString())
          .where((t) => t.isNotEmpty)
          .toList();
      if (tags != null && tags.isNotEmpty) tagsMap[id] = tags;
    }

    // Parse playlists
    final playlists = <(String, List<String>)>[];
    final rawPlaylists = meta['playlists'] as List<dynamic>?;
    if (rawPlaylists != null) {
      for (final pl in rawPlaylists) {
        final title = pl['title']?.toString() ?? '';
        final songIds = (pl['songs'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .toList() ??
            [];
        if (title.isNotEmpty) playlists.add((title, songIds));
      }
    }

    return (songs, tagsMap, playlists);
  }

  static (List<Song>, Map<String, List<String>>) _importFallback(
      Archive archive) {
    final songs = <Song>[];
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final name = file.name.toLowerCase();
      if (!name.endsWith('.chopro') && !name.endsWith('.cho')) continue;
      final body = utf8.decode(file.content as List<int>);
      songs.add(Utils.parseSongFromChordPro(body));
    }
    return (songs, {});
  }

  // ── Playlist persistence ─────────────────────────────────────────────────────

  /// Create playlists from import data and link songs.
  ///
  /// [idMap] maps original song IDs (from the pack) → locally assigned IDs
  /// (which may differ when a song was saved with a new UUID on conflict).
  static Future<void> savePlaylists(
    List<(String, List<String>)> playlists,
    Map<String, String> idMap,
  ) async {
    for (final (title, songIds) in playlists) {
      final existing = await DBProvider.db.hasPlaylist(title);
      final plId = existing.isNotEmpty
          ? existing.first.id
          : await DBProvider.db.newPlaylist(title);

      for (final origId in songIds) {
        final localId = idMap[origId];
        if (localId != null) {
          await DBProvider.db.newSongPlaylistRaw(plId, localId);
        }
      }
    }
  }

  // ── Tag persistence ─────────────────────────────────────────────────────────

  /// Persist imported tags for a song that was just inserted/updated.
  static Future<void> saveTags(String songId, List<String> tags) async {
    await DBProvider.db.deleteTagsBySongId(songId);
    final db = await DBProvider.db.database;
    for (final tag in tags) {
      await db.insert('Tag', {'idSong': songId, 'tag': tag});
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _filename(Song song) {
    final base = (song.author != null && song.author!.isNotEmpty)
        ? '${song.title} - ${song.author}'
        : song.title;
    return '${base.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim()}.chopro';
  }
}
