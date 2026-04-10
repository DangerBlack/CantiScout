import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';

import '../model/Song.dart';
import '../model/Tag.dart';

/// UUIDs and wire-protocol helpers for BLE song transfer.
class BleTransferController {
  // ── GATT UUIDs ──────────────────────────────────────────────────────────────

  static const String kServiceUuid =
      '0000AA00-0000-1000-8000-00805F9B34FB';
  static const String kDataCharUuid =
      '0000AA01-0000-1000-8000-00805F9B34FB';
  static const String kControlCharUuid =
      '0000AA02-0000-1000-8000-00805F9B34FB';

  // ── Protocol constants ──────────────────────────────────────────────────────

  static const int kChunkPayloadSize = 480; // bytes per BLE notification
  static const String kCommandStart = 'START';
  static const String kDeviceName = 'CantScout';

  // Special header bytes for the DONE marker packet
  static const int _kDone = 0xFF;

  // ── Encoding ────────────────────────────────────────────────────────────────

  /// Serialise [songs] into fixed-size binary chunks ready for BLE NOTIFY.
  ///
  /// Wire format (v2):
  ///   Payload = gzip( UTF-8 JSON matching chopack metadata format with
  ///             inlined `body` and `tags` fields )
  ///
  /// Chunk layout:
  ///   [0-1] chunk index  — uint16 big-endian
  ///   [2-3] total chunks — uint16 big-endian
  ///   [4…]  payload      — raw bytes of the gzip stream fragment
  ///
  /// Each [Song] must have its [Song.tags] populated before calling this.
  /// [playlists] is a list of (playlistTitle, [songIds]) to embed in the payload.
  static List<Uint8List> buildChunks(
    List<Song> songs, {
    List<(String, List<String>)> playlists = const [],
  }) {
    final json = jsonEncode({
      'version': 2,
      'songs': songs.map((s) => {
            'id': s.id,
            'title': s.title,
            'author': s.author ?? '',
            'time': s.time,
            'status': s.status,
            'tags': s.tags.map((t) => t.tag).toList(),
            'body': s.body,
          }).toList(),
      'playlists': playlists
          .map((p) => {'title': p.$1, 'songs': p.$2})
          .toList(),
    });

    final compressed = Uint8List.fromList(
      GZipEncoder().encode(Uint8List.fromList(utf8.encode(json)))!,
    );

    final total = (compressed.length / kChunkPayloadSize).ceil();
    final chunks = <Uint8List>[];

    for (int i = 0; i < total; i++) {
      final start = i * kChunkPayloadSize;
      final end = min(start + kChunkPayloadSize, compressed.length);
      final payload = compressed.sublist(start, end);

      final chunk = Uint8List(4 + payload.length);
      chunk[0] = (i >> 8) & 0xFF;
      chunk[1] = i & 0xFF;
      chunk[2] = (total >> 8) & 0xFF;
      chunk[3] = total & 0xFF;
      chunk.setRange(4, chunk.length, payload);
      chunks.add(chunk);
    }
    return chunks;
  }

  /// 4-byte packet that signals end of transfer.
  static Uint8List buildDonePacket() =>
      Uint8List.fromList([_kDone, _kDone, _kDone, _kDone]);

  // ── Decoding ────────────────────────────────────────────────────────────────

  /// Returns true if [bytes] is the DONE marker.
  static bool isDonePacket(List<int> bytes) =>
      bytes.length == 4 &&
      bytes[0] == _kDone &&
      bytes[1] == _kDone &&
      bytes[2] == _kDone &&
      bytes[3] == _kDone;

  /// Extracts (index, total) from the 4-byte chunk header.
  static (int index, int total) parseHeader(List<int> bytes) {
    final index = (bytes[0] << 8) | bytes[1];
    final total = (bytes[2] << 8) | bytes[3];
    return (index, total);
  }

  /// Reassembles [chunkMap] (index → raw packet).
  ///
  /// Returns `(songs, playlists)` where each [Song] has its [Song.tags]
  /// populated and `playlists` is a list of (title, [songIds]).
  /// Returns null if any chunk is missing or the payload is malformed.
  static ({List<Song> songs, List<(String, List<String>)> playlists})?
      parseChunks(Map<int, List<int>> chunkMap, int total) {
    try {
      final buffer = <int>[];
      for (int i = 0; i < total; i++) {
        final c = chunkMap[i];
        if (c == null) return null;
        buffer.addAll(c.sublist(4)); // skip 4-byte header
      }

      final decompressed = GZipDecoder().decodeBytes(buffer);
      final data = jsonDecode(utf8.decode(decompressed)) as Map<String, dynamic>;

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
          tagStrings.map((t) => Tag(id: 0, idSong: song.id, tag: t)).toList(),
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
