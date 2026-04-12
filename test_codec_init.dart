import 'dart:typed_data';
import 'lib/controller/ReedSolomonCodec.dart';

void main() {
  print('Testing library-level GF tables...');
  
  final payload = Uint8List.fromList([72]); // "H"
  final encoder = RsEncoder(payload, blockSize: 8);
  final frames = encoder.encode();
  
  print('Encoded ${frames.length} frames');
  print('Frame 0 data: ${frames[0].data.sublist(0, 8).join(", ")}');
  print('Frame 1 data: ${frames[1].data.sublist(0, 8).join(", ")}');
  
  final decoder = RsDecoder(n: encoder.n, k: encoder.k, blockSize: encoder.blockSize, payloadSize: encoder.payloadSize);
  decoder.addFrame(frames[0]);
  
  final result = decoder.reconstruct();
  print('Decoded: ${result != null ? result.sublist(0, 1).join(", ") : "null"} (expected: 72)');
}
