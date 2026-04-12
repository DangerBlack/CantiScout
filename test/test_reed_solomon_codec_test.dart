import 'dart:typed_data';
import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:canti_scout/controller/ReedSolomonCodec.dart';

void main() {
  test('Single byte encode/decode', () {
    final src = Uint8List.fromList([0xAB]);
    final encoder = RsEncoder(src, blockSize: 1);
    final frames = encoder.encode();

    expect(frames.length, equals(2));

    final decoder = RsDecoder(
      n: frames.length,
      k: 1,
      blockSize: 1,
      payloadSize: 1,
    );
    decoder.addFrame(frames[0]);

    final result = decoder.reconstruct();
    expect(result, equals(src));
  });

  test('Two bytes with k=2, n=4', () {
    final src = Uint8List.fromList([0x12, 0x34]);
    final encoder = RsEncoder(src, blockSize: 1);
    final frames = encoder.encode();

    expect(frames.length, equals(4));

    // Try some combinations
    for (var i = 0; i < 4; i++) {
      for (var j = i + 1; j < 4; j++) {
        final decoder = RsDecoder(n: 4, k: 2, blockSize: 1, payloadSize: 2);
        decoder.addFrame(frames[i]);
        decoder.addFrame(frames[j]);
        final result = decoder.reconstruct();
        expect(result, equals(src), reason: 'Failed with shards $i,$j');
      }
    }
  });

  test('10 bytes with k=2, n=4', () {
    final src = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    final encoder = RsEncoder(src, blockSize: 5);
    final frames = encoder.encode();

    expect(frames.length, equals(4));
    expect(frames[0].data.length, equals(5));

    // Try shards 0,1
    final decoder1 = RsDecoder(n: 4, k: 2, blockSize: 5, payloadSize: 10);
    decoder1.addFrame(frames[0]);
    decoder1.addFrame(frames[1]);
    final result1 = decoder1.reconstruct();
    expect(result1, equals(src));

    // Try shards 2,3
    final decoder2 = RsDecoder(n: 4, k: 2, blockSize: 5, payloadSize: 10);
    decoder2.addFrame(frames[2]);
    decoder2.addFrame(frames[3]);
    final result2 = decoder2.reconstruct();
    expect(result2, equals(src));
  });

  test('100 bytes, default k, n', () {
    final src = Uint8List.fromList([for (var i = 0; i < 100; i++) i]);
    final encoder = RsEncoder(src);
    final frames = encoder.encode();

    final k = math.max(1, (src.length / encoder.blockSize).ceil());

    // Try first k shards
    final decoder = RsDecoder(
      n: frames.length,
      k: k,
      blockSize: encoder.blockSize,
      payloadSize: src.length,
    );
    for (var i = 0; i < k; i++) decoder.addFrame(frames[i]);

    final result = decoder.reconstruct();
    expect(result, equals(src));
  });
}
