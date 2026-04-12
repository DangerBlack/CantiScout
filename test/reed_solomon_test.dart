import 'dart:typed_data';
import 'package:test/test.dart';
import '../lib/controller/ReedSolomonCodec.dart';

void main() {
  group('Reed-Solomon Codec', () {
    test('encodes and decodes small payload', () {
      const message = 'Hello, World!';
      final payload = Uint8List.fromList(message.codeUnits);

      final encoder = RsEncoder(payload, blockSize: 500);
      final frames = encoder.encode();

      expect(frames.length, equals(encoder.n));
      expect(encoder.k, equals(encoder.k));

      final decoder = RsDecoder(
        n: encoder.n,
        k: encoder.k,
        blockSize: encoder.blockSize,
        payloadSize: encoder.payloadSize,
      );

      frames.forEach((frame) {
        decoder.addFrame(frame);
      });

      expect(decoder.isComplete, isTrue);
      final result = decoder.reconstruct();
      expect(result, isNotNull);
      expect(String.fromCharCodes(result!.toList()), equals(message));
    });

    test('decodes with only k shards out of n', () {
      const message =
          'Test message for Reed-Solomon encoding - this is longer to test multiple blocks';
      final payload = Uint8List.fromList(message.codeUnits);

      final encoder = RsEncoder(payload, blockSize: 50);
      final frames = encoder.encode();

      expect(frames.length, greaterThan(encoder.k));

      final decoder = RsDecoder(
        n: encoder.n,
        k: encoder.k,
        blockSize: encoder.blockSize,
        payloadSize: encoder.payloadSize,
      );

      // Add only first k frames (simulate packet loss)
      for (int i = 0; i < encoder.k; i++) {
        decoder.addFrame(frames[i]);
      }

      expect(decoder.isComplete, isTrue);
      final result = decoder.reconstruct();
      expect(String.fromCharCodes(result!.toList()), equals(message));
    });

    test('decodes with arbitrary k shards', () {
      const message = 'Arbitrary shard selection test';
      final payload = Uint8List.fromList(message.codeUnits);

      final encoder = RsEncoder(payload, blockSize: 100);
      final frames = encoder.encode();

      final decoder = RsDecoder(
        n: encoder.n,
        k: encoder.k,
        blockSize: encoder.blockSize,
        payloadSize: encoder.payloadSize,
      );

      // Add only last k frames
      for (int i = frames.length - encoder.k; i < frames.length; i++) {
        decoder.addFrame(frames[i]);
      }

      expect(decoder.isComplete, isTrue);
      final result = decoder.reconstruct();
      expect(String.fromCharCodes(result!.toList()), equals(message));
    });

    test('frame serialization roundtrip', () {
      const message = 'Test serialization';
      final payload = Uint8List.fromList(message.codeUnits);

      final encoder = RsEncoder(payload);
      final frames = encoder.encode();

      for (final frame in frames) {
        final qrData = frame.toQrData();
        final decoded = RsFrame.fromQrData(qrData);

        expect(decoded, isNotNull);
        expect(decoded!.shardIndex, equals(frame.shardIndex));
        expect(decoded.numBlocks, equals(frame.numBlocks));
        expect(decoded.payloadSize, equals(frame.payloadSize));
        expect(decoded.data, equals(frame.data));
      }
    });

    test('handles larger payload with 500-byte blocks', () {
      // Generate ~2KB of test data
      final payload = Uint8List(2048);
      for (int i = 0; i < payload.length; i++) {
        payload[i] = i % 256;
      }

      final encoder = RsEncoder(payload, blockSize: 500);
      final frames = encoder.encode();

      // 2048/500 = ~5 source blocks, so n = 10 total frames
      expect(encoder.k, equals(5));
      expect(encoder.n, equals(10));
      expect(frames.length, equals(10));

      // Verify we can reconstruct with any 5 frames
      for (int start = 0; start <= 5; start++) {
        final decoder = RsDecoder(
          n: encoder.n,
          k: encoder.k,
          blockSize: encoder.blockSize,
          payloadSize: encoder.payloadSize,
        );

        for (int i = start; i < start + encoder.k; i++) {
          decoder.addFrame(frames[i]);
        }

        expect(decoder.isComplete, isTrue);
        final result = decoder.reconstruct();
        expect(result, equals(payload));
      }
    });

    test('progress tracking', () {
      const message = 'Progress test';
      final payload = Uint8List.fromList(message.codeUnits);

      final encoder = RsEncoder(payload, blockSize: 10);
      final frames = encoder.encode();

      final decoder = RsDecoder(
        n: encoder.n,
        k: encoder.k,
        blockSize: encoder.blockSize,
        payloadSize: encoder.payloadSize,
      );

      expect(decoder.progress, equals(0.0));

      decoder.addFrame(frames[0]);
      expect(decoder.progress, equals(1.0 / encoder.k));

      decoder.addFrame(frames[1]);
      expect(decoder.progress, equals(2.0 / encoder.k));
    });
  });
}
