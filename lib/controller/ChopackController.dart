import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../Database.dart';
import '../model/Song.dart';
import '../model/Tag.dart';
import 'Utils.dart';

/// Handles `.chopack` export and import.
///
/// A `.chopack` is a ZIP file containing:
///   - `metadata.json`  — all song metadata + tags (primary source on import)
///   - `{title}.chopro` — one ChordPro file per song (human-readable body)
class ChopackController {
  static const String _kMeta = 'metadata.json';

  // ── Export ──────────────────────────────────────────────────────────────────

  /// Build and share a `.chopack` for [songs].
  /// [packName] is used as the filename (no extension).
  static Future<void> exportPack(List<Song> songs, String packName) async {
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

    // Add metadata.json
    final metaBytes = utf8.encode(jsonEncode({
      'version': 1,
      'exported': DateTime.now().toIso8601String(),
      'songs': metaSongs,
    }));
    archive.addFile(ArchiveFile(_kMeta, metaBytes.length, metaBytes));

    // Write ZIP to temp file and share
    final zipBytes = ZipEncoder().encode(archive)!;
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
  /// Returns `(songs, tagsMap)` where tagsMap is songId → tag strings.
  /// Falls back to parsing `.chopro` files if `metadata.json` is absent.
  static Future<(List<Song>, Map<String, List<String>>)> importPack(
      String path) async {
    final zipBytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final metaFile = archive.findFile(_kMeta);
    if (metaFile != null) {
      return _importWithMeta(archive, metaFile);
    } else {
      return _importFallback(archive);
    }
  }

  static (List<Song>, Map<String, List<String>>) _importWithMeta(
      Archive archive, ArchiveFile metaFile) {
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

      final id = entry['id']?.toString() ?? const Uuid().v4();
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

    return (songs, tagsMap);
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

  // ── Tag persistence ─────────────────────────────────────────────────────────

  /// Persist imported tags for a song that was just inserted/updated.
  static Future<void> saveTags(String songId, List<String> tags) async {
    await DBProvider.db.deleteTagsBySongId(songId);
    for (final tag in tags) {
      await DBProvider.db.newTag(Tag(id: 0, idSong: songId, tag: tag));
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
