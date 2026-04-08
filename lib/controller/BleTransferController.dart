import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../model/Song.dart';

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
  /// Chunk layout:
  ///   [0-1] chunk index  — uint16 big-endian
  ///   [2-3] total chunks — uint16 big-endian
  ///   [4…]  payload      — UTF-8 JSON fragment
  static List<Uint8List> buildChunks(List<Song> songs) {
    final jsonBytes = Uint8List.fromList(
      utf8.encode(jsonEncode({
        'version': 1,
        'songs': songs.map((s) => s.toMap()).toList(),
      })),
    );

    final total = (jsonBytes.length / kChunkPayloadSize).ceil();
    final chunks = <Uint8List>[];

    for (int i = 0; i < total; i++) {
      final start = i * kChunkPayloadSize;
      final end = min(start + kChunkPayloadSize, jsonBytes.length);
      final payload = jsonBytes.sublist(start, end);

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

  /// Reassembles [chunkMap] (index → raw packet) into a list of [Song]s.
  /// Returns null if any chunk is missing or the JSON is malformed.
  static List<Song>? parseChunks(Map<int, List<int>> chunkMap, int total) {
    try {
      final buffer = <int>[];
      for (int i = 0; i < total; i++) {
        final c = chunkMap[i];
        if (c == null) return null;
        buffer.addAll(c.sublist(4)); // skip 4-byte header
      }
      final data =
          jsonDecode(utf8.decode(buffer)) as Map<String, dynamic>;
      final list = data['songs'] as List<dynamic>;
      return list
          .map((s) => Song.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
