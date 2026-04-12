import 'dart:typed_data';

void main() {
  // Simple GF(256) test
  print('Testing GF(256) in isolation...');

  // Generate exp/log tables
  final expTable = List<int>.generate(512, (i) => 0);
  final logTable = List<int>.generate(256, (i) => 0);

  var x = 1;
  for (var i = 0; i < 255; i++) {
    expTable[i] = x;
    logTable[x] = i;
    x <<= 1;
    if (x >= 256) x ^= 0x11D;
    expTable[i + 255] = x;
  }

  print('expTable[0] = ${expTable[0]} (should be 1)');
  print('expTable[1] = ${expTable[1]} (should be 2)');
  print('expTable[8] = ${expTable[8]} (should be 256%251 = 5)');
  print('expTable[255] = ${expTable[255]} (should be 1)');
  print('expTable[256] = ${expTable[256]} (should be 2)');
  print('logTable[1] = ${logTable[1]} (should be 0)');
  print('logTable[2] = ${logTable[2]} (should be 1)');

  // Test gfMul
  int gfMul(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return expTable[(logTable[a] + logTable[b]) % 255];
  }

  print('2 * 3 = ${gfMul(2, 3)} (should be 6)');
  print('3 * 255 = ${gfMul(3, 255)} (in GF(256))');

  // Test encode/decode k=1, n=2
  print('\nTesting k=1, n=2 encode/decode:');
  final payload = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
  print('Original: ${payload.join(", ")} = "${String.fromCharCodes(payload)}"');

  // k=1, blockSize=8, n=2
  final blockSize = 8;
  final k = 1;
  final n = 2;

  // Source shard (padded to 8 bytes)
  final src = Uint8List(blockSize)..setRange(0, 5, payload);
  print('Source shard: ${src.join(", ")}');

  // Encode: shard[j][b] = alpha^(j*0) * src[0][b] = 1 * src[0][b]
  final shards = <Uint8List>[];
  for (var j = 0; j < n; j++) {
    final shard = Uint8List(blockSize);
    for (var b = 0; b < blockSize; b++) {
      var sum = 0;
      for (var i = 0; i < k; i++) {
        sum ^= gfMul(expTable[(j * i) % 255], src[b]);
      }
      shard[b] = sum;
    }
    shards.add(shard);
    print('Shard $j: ${shard.join(", ")}');
  }

  // Decode using shard 0
  print('\nDecoding using shard 0:');
  final idx = [0];

  // Build Vandermonde V[m][i] = alpha^(idx[m] * i)
  final V = List.generate(
      k, (m) => List.generate(k, (i) => expTable[(idx[m] * i) % 255]));
  print('Vandermonde V = $V (should be [[1]])');

  // Invert (1x1 matrix: V = [1], V^-1 = [1])
  final inv = List.generate(k, (i) => List.generate(k, (j) => 0));
  inv[0][0] =
      gfMul(V[0][0], gfMul(V[0][0], 1) == V[0][0] ? 1 : 1); // Should be [1]
  print('V^-1 = $inv');

  // Actually, for 1x1, just use the inverse directly
  final v00_inv = 1; // inv[0][0]

  // Reconstruct
  final decoded = Uint8List(blockSize);
  for (var b = 0; b < blockSize; b++) {
    decoded[b] = gfMul(v00_inv, shards[0][b]);
  }
  print('Decoded: ${decoded.join(", ")}');
  print('Decoded string: "${String.fromCharCodes(decoded.sublist(0, 5))}"');

  // Verify match
  var match = true;
  for (var i = 0; i < 5; i++) {
    if (decoded[i] != payload[i]) {
      match = false;
      print(
          'MISMATCH at $i: decoded[${i}]=${decoded[i]}, payload[${i}]=${payload[i]}');
    }
  }
  print('Match: ${match ? "YES ✓" : "NO ✗"}');
}
