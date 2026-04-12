import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';

import '../model/Song.dart';
import '../model/Tag.dart';

/// Builds and parses the gzip+JSON payload used by the QR fountain transfer.
///
/// Wire format is identical to the BLE transfer payload so that a future
/// multi-transport receiver can accept both without any schema change.
class QrTransferController {
  // ── Serialisation ───────────────────────────────────────────────────────────

  /// Serialise [songs] (with tags pre-populated) and optional [playlists]
  /// into a gzip-compressed JSON blob ready for the fountain encoder.
  static Uint8List buildPayload(
    List<Song> songs, {
    List<(String, List<String>)> playlists = const [],
  }) {
    final json = jsonEncode({
      'version': 2,
      'songs': songs
          .map((s) => {
                'id': s.id,
                'title': s.title,
                'author': s.author ?? '',
                'time': s.time,
                'status': s.status,
                'tags': s.tags.map((t) => t.tag).toList(),
                'body': s.body,
              })
          .toList(),
      'playlists': playlists
          .map((p) => {'title': p.$1, 'songs': p.$2})
          .toList(),
    });

    return Uint8List.fromList(
      GZipEncoder().encode(Uint8List.fromList(utf8.encode(json))),
    );
  }

  // ── Deserialisation ─────────────────────────────────────────────────────────

  /// Parse a raw gzip+JSON payload back into songs and playlists.
  /// Returns null if the data is malformed or decompression fails.
  static ({List<Song> songs, List<(String, List<String>)> playlists})?
      parsePayload(Uint8List compressed) {
    try {
      final decompressed = GZipDecoder().decodeBytes(compressed);
      final data =
          jsonDecode(utf8.decode(decompressed)) as Map<String, dynamic>;

      final songs = (data['songs'] as List<dynamic>).map((entry) {
        final m = entry as Map<String, dynamic>;
        final song = Song(
          id: m['id']?.toString().isNotEmpty == true
              ? m['id'].toString()
              : const Uuid().v4(),
          title: m['title']?.toString() ?? '',
          author: m['author'] != null && m['author'].toString().isNotEmpty
              ? m['author'].toString()
              : null,
          time: m['time']?.toString() ?? DateTime.now().toIso8601String(),
          body: m['body']?.toString() ?? '',
          status: int.tryParse(m['status']?.toString() ?? '0') ?? 0,
        );
        final tagStrings = (m['tags'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .where((t) => t.isNotEmpty)
                .toList() ??
            [];
        song.setTags(
          tagStrings
              .map((t) => Tag(id: 0, idSong: song.id, tag: t))
              .toList(),
        );
        return song;
      }).toList();

      final playlists = <(String, List<String>)>[];
      final rawPl = data['playlists'] as List<dynamic>?;
      if (rawPl != null) {
        for (final pl in rawPl) {
          final title = pl['title']?.toString() ?? '';
          final ids = (pl['songs'] as List<dynamic>?)
                  ?.map((s) => s.toString())
                  .toList() ??
              [];
          if (title.isNotEmpty) playlists.add((title, ids));
        }
      }

      return (songs: songs, playlists: playlists);
    } catch (_) {
      return null;
    }
  }
}
