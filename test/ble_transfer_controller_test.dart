import 'package:test/test.dart';

import '../lib/controller/BleTransferController.dart';
import '../lib/model/Song.dart';
import '../lib/model/Tag.dart';

Song _makeSong({
  String id = 'test-id-1',
  String title = 'Test Song',
  String? author = 'Test Author',
  String body = '{title: Test Song}\n{artist: Test Author}\nVerse 1\n',
  List<String> tagStrings = const [],
}) {
  final song = Song(
    id: id,
    title: title,
    author: author,
    time: '2024-01-01T00:00:00.000Z',
    body: body,
  );
  song.setTags(tagStrings.map((t) => Tag(id: 0, idSong: id, tag: t)).toList());
  return song;
}

/// Builds a chunk map (index → raw packet) from a list of chunks, as
/// BleReceiveView accumulates them during a real transfer.
Map<int, List<int>> _toChunkMap(List chunks) {
  final map = <int, List<int>>{};
  for (final c in chunks) {
    final (idx, _) = BleTransferController.parseHeader(c);
    map[idx] = c;
  }
  return map;
}

void main() {
  group('BleTransferController', () {
    // ── Done packet ──────────────────────────────────────────────────────────

    group('done packet', () {
      test('buildDonePacket returns 4-byte 0xFF marker', () {
        final done = BleTransferController.buildDonePacket();
        expect(done.length, equals(4));
        expect(done.every((b) => b == 0xFF), isTrue);
      });

      test('isDonePacket detects the marker', () {
        expect(BleTransferController.isDonePacket([0xFF, 0xFF, 0xFF, 0xFF]),
            isTrue);
        expect(BleTransferController.isDonePacket([0xFF, 0xFF, 0xFF, 0xFE]),
            isFalse);
        expect(BleTransferController.isDonePacket([0xFF, 0xFF, 0xFF]),
            isFalse);
        expect(BleTransferController.isDonePacket([]), isFalse);
      });

      test('isDonePacket rejects a normal data chunk', () {
        final chunks = BleTransferController.buildChunks([_makeSong()]);
        expect(BleTransferController.isDonePacket(chunks.first), isFalse);
      });
    });

    // ── parseHeader ──────────────────────────────────────────────────────────

    group('parseHeader', () {
      test('chunk 0 of 3', () {
        final (idx, tot) =
            BleTransferController.parseHeader([0x00, 0x00, 0x00, 0x03, 0xAA]);
        expect(idx, equals(0));
        expect(tot, equals(3));
      });

      test('large values use big-endian correctly', () {
        // chunk 300 (0x012C) of 1000 (0x03E8)
        final (idx, tot) =
            BleTransferController.parseHeader([0x01, 0x2C, 0x03, 0xE8]);
        expect(idx, equals(300));
        expect(tot, equals(1000));
      });
    });

    // ── buildChunks structure ────────────────────────────────────────────────

    group('buildChunks', () {
      test('every chunk has at least a 4-byte header', () {
        final chunks = BleTransferController.buildChunks([_makeSong()]);
        for (final chunk in chunks) {
          expect(chunk.length, greaterThanOrEqualTo(4));
        }
      });

      test('chunk headers encode monotonically increasing index', () {
        // Use many unique songs so gzip cannot collapse the payload to one chunk
        final songs = List.generate(
          60,
          (i) => _makeSong(
            id: 'unique-id-$i-abcdefghij',
            title: 'Unique Song Title $i',
            body: 'Verse $i line 1\nVerse $i line 2\n' * 5,
          ),
        );
        final chunks = BleTransferController.buildChunks(songs);
        expect(chunks.length, greaterThan(1),
            reason: 'Expected multiple chunks for 60 songs');

        for (int i = 0; i < chunks.length; i++) {
          final (idx, tot) = BleTransferController.parseHeader(chunks[i]);
          expect(idx, equals(i));
          expect(tot, equals(chunks.length));
        }
      });

      test('payload portion never exceeds kChunkPayloadSize', () {
        final manySongs = List.generate(
          60,
          (i) => _makeSong(
            id: 'unique-id-$i-abcdefghij',
            title: 'Unique Song Title $i',
            body: 'Verse $i line 1\nVerse $i line 2\n' * 5,
          ),
        );
        final chunks = BleTransferController.buildChunks(manySongs);
        for (final chunk in chunks) {
          expect(chunk.length - 4,
              lessThanOrEqualTo(BleTransferController.kChunkPayloadSize));
        }
      });
    });

    // ── Roundtrip ────────────────────────────────────────────────────────────

    group('roundtrip', () {
      test('single song, no tags, no playlists', () {
        final original = _makeSong();
        final chunks = BleTransferController.buildChunks([original]);
        final result =
            BleTransferController.parseChunks(_toChunkMap(chunks), chunks.length);

        expect(result, isNotNull);
        expect(result!.songs.length, equals(1));
        expect(result.songs[0].title, equals('Test Song'));
        expect(result.songs[0].author, equals('Test Author'));
        expect(result.songs[0].body, equals(original.body));
        expect(result.playlists, isEmpty);
      });

      test('song with tags', () {
        final original =
            _makeSong(tagStrings: ['scout', 'liturgical', 'campfire']);
        final chunks = BleTransferController.buildChunks([original]);
        final result =
            BleTransferController.parseChunks(_toChunkMap(chunks), chunks.length);

        expect(result, isNotNull);
        final tags = result!.songs[0].tags.map((t) => t.tag).toList()..sort();
        expect(tags, equals(['campfire', 'liturgical', 'scout']));
      });

      test('song without author', () {
        final original = _makeSong(author: null);
        final chunks = BleTransferController.buildChunks([original]);
        final result =
            BleTransferController.parseChunks(_toChunkMap(chunks), chunks.length);

        expect(result, isNotNull);
        // author was null → serialised as '' → parsed back as null
        expect(result!.songs[0].author, isNull);
      });

      test('multiple songs', () {
        final songs = [
          _makeSong(id: 'id-1', title: 'Song One', tagStrings: ['tag1']),
          _makeSong(id: 'id-2', title: 'Song Two', tagStrings: ['tag2']),
          _makeSong(id: 'id-3', title: 'Song Three'),
        ];
        final chunks = BleTransferController.buildChunks(songs);
        final result =
            BleTransferController.parseChunks(_toChunkMap(chunks), chunks.length);

        expect(result, isNotNull);
        expect(result!.songs.length, equals(3));
        final titles = result.songs.map((s) => s.title).toSet();
        expect(titles, containsAll(['Song One', 'Song Two', 'Song Three']));
      });

      test('playlists survive roundtrip', () {
        final songs = [
          _makeSong(id: 'id-1', title: 'Song One'),
          _makeSong(id: 'id-2', title: 'Song Two'),
        ];
        final playlists = [
          ('Sunday Mass', ['id-1', 'id-2']),
          ('Campfire Night', ['id-1']),
        ];

        final chunks =
            BleTransferController.buildChunks(songs, playlists: playlists);
        final result =
            BleTransferController.parseChunks(_toChunkMap(chunks), chunks.length);

        expect(result, isNotNull);
        expect(result!.playlists.length, equals(2));

        final pl0 = result.playlists[0];
        expect(pl0.$1, equals('Sunday Mass'));
        expect(pl0.$2, equals(['id-1', 'id-2']));

        final pl1 = result.playlists[1];
        expect(pl1.$1, equals('Campfire Night'));
        expect(pl1.$2, equals(['id-1']));
      });

      test('missing chunk returns null', () {
        final song = _makeSong(body: 'x' * 5000);
        final chunks = BleTransferController.buildChunks([song]);

        if (chunks.length < 2) {
          // Can't drop a chunk if there's only one — skip
          return;
        }

        final map = _toChunkMap(chunks);
        map.remove(0); // simulate packet loss

        final result = BleTransferController.parseChunks(map, chunks.length);
        expect(result, isNull);
      });

      test('large payload — 20 songs each with tags', () {
        final songs = List.generate(
          20,
          (i) => _makeSong(
            id: 'song-$i',
            title: 'Song $i',
            body: 'Verse 1\nChorus\nVerse 2\n' * 10,
            tagStrings: ['tag-$i', 'common'],
          ),
        );

        final chunks = BleTransferController.buildChunks(songs);
        final result =
            BleTransferController.parseChunks(_toChunkMap(chunks), chunks.length);

        expect(result, isNotNull);
        expect(result!.songs.length, equals(20));
        for (int i = 0; i < 20; i++) {
          final s = result.songs.firstWhere((s) => s.id == 'song-$i');
          expect(s.title, equals('Song $i'));
          // tags include 'tag-$i' and 'common'
          expect(s.tags.length, equals(2));
        }
      });

      test('unicode content in title/author/body', () {
        final original = _makeSong(
          title: 'Canto d\'Amore',
          author: 'François',
          body: 'Àmor e Grażyna\nñoño\n',
        );
        final chunks = BleTransferController.buildChunks([original]);
        final result =
            BleTransferController.parseChunks(_toChunkMap(chunks), chunks.length);

        expect(result, isNotNull);
        expect(result!.songs[0].title, equals('Canto d\'Amore'));
        expect(result.songs[0].author, equals('François'));
        expect(result.songs[0].body, contains('Àmor'));
      });
    });
  });
}
