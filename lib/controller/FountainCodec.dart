import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

// ── Deterministic 32-bit xorshift PRNG ─────────────────────────────────────
// All codec operations use this instead of dart:math.Random so that the
// encoder and decoder produce identical sequences across platforms.

int _xorshift32(int state) {
  if (state == 0) return 1; // xorshift(0) = 0 forever — avoid the trap
  state = (state ^ (state << 13)) & 0xFFFFFFFF;
  state = (state ^ (state >> 17)) & 0xFFFFFFFF;
  state = (state ^ (state << 5)) & 0xFFFFFFFF;
  return state == 0 ? 1 : state;
}

// Sample degree from the ideal soliton distribution for K source blocks.
// Uses a dedicated PRNG lane (seed XOR constant) so it doesn't interfere
// with the neighbor-selection lane.
int _sampleDegree(int seed, int k) {
  if (k == 1) return 1;
  // Generate a uniform float in [0, 1)
  final state = _xorshift32(seed ^ 0x9E3779B9);
  final r = (state & 0x7FFFFFFF) / 0x80000000;

  // CDF of ideal soliton:
  //   P(d=1) = 1/k
  //   P(d=j) = 1/(j*(j-1))  for j = 2..k
  double cdf = 1.0 / k;
  if (r < cdf) return 1;
  for (int d = 2; d <= k; d++) {
    cdf += 1.0 / (d * (d - 1).toDouble());
    if (r < cdf) return d;
  }
  return k;
}

// Select [degree] unique source-block indices for the given seed.
List<int> _getNeighbors(int seed, int degree, int numBlocks) {
  final chosen = <int>{};
  int state = seed;
  // Limit attempts to avoid infinite loop when degree ≥ numBlocks
  final limit = degree * 4 + numBlocks;
  int attempts = 0;
  while (chosen.length < degree && attempts < limit) {
    state = _xorshift32(state);
    chosen.add(state % numBlocks);
    attempts++;
  }
  return chosen.toList();
}

// ── Frame format ────────────────────────────────────────────────────────────
//
//  [0]     magic      = 0xCA
//  [1-2]   numBlocks  uint16 BE
//  [3-6]   payloadSize uint32 BE   (original unpadded byte count)
//  [7-10]  seed       uint32 BE
//  [11…]   symbolData (blockSize bytes)
//
// Frames are base64-encoded for embedding in a QR string.

const int _kMagic = 0xCA;
const int _kHeaderSize = 11;

/// A single LT-coded fountain frame.
class FountainFrame {
  final int numBlocks;
  final int payloadSize;
  final int seed;
  final Uint8List data; // exactly blockSize bytes

  const FountainFrame({
    required this.numBlocks,
    required this.payloadSize,
    required this.seed,
    required this.data,
  });

  int get blockSize => data.length;

  /// Encode to raw bytes.
  Uint8List toBytes() {
    final out = ByteData(_kHeaderSize + data.length);
    out.setUint8(0, _kMagic);
    out.setUint16(1, numBlocks, Endian.big);
    out.setUint32(3, payloadSize, Endian.big);
    out.setUint32(7, seed, Endian.big);
    final buf = out.buffer.asUint8List();
    buf.setRange(_kHeaderSize, buf.length, data);
    return buf;
  }

  /// Encode as a base64 string for use as QR data.
  String toQrData() => base64.encode(toBytes());

  /// Parse from a QR string. Returns null if the string is not a valid frame.
  static FountainFrame? fromQrData(String qrData) {
    try {
      return fromBytes(base64.decode(qrData));
    } catch (_) {
      return null;
    }
  }

  /// Parse from raw bytes. Returns null on invalid input.
  static FountainFrame? fromBytes(Uint8List bytes) {
    if (bytes.length <= _kHeaderSize) return null;
    if (bytes[0] != _kMagic) return null;
    final view = ByteData.sublistView(bytes);
    final numBlocks = view.getUint16(1, Endian.big);
    final payloadSize = view.getUint32(3, Endian.big);
    final seed = view.getUint32(7, Endian.big);
    if (numBlocks == 0 || payloadSize == 0) return null;
    final data = bytes.sublist(_kHeaderSize);
    return FountainFrame(
        numBlocks: numBlocks,
        payloadSize: payloadSize,
        seed: seed,
        data: data);
  }
}

// ── Encoder ─────────────────────────────────────────────────────────────────

/// Splits a payload into source blocks and generates an infinite stream of
/// LT-coded [FountainFrame]s. Call [next] repeatedly to produce frames.
class FountainEncoder {
  /// Symbol (block) size in bytes. Override at build time with:
  ///   flutter run --dart-define=QR_BLOCK_SIZE=500
  ///
  /// Budget: QR v40 Medium ECC holds 2,331 bytes in byte mode.
  /// Frame = 11-byte header + blockSize → base64 → ceil((11+blockSize)/3)×4 chars.
  /// 500 → frame 511 → 684 base64 chars — tiny, robust at any distance.
  /// 1700 → frame 1711 → 2284 base64 chars — near the v40-M ceiling.
  static const int defaultBlockSize =
      int.fromEnvironment('QR_BLOCK_SIZE', defaultValue: 500);

  final List<Uint8List> _blocks;
  final int numBlocks;
  final int payloadSize;
  final int blockSize;
  int _counter = 1; // seed; never 0

  FountainEncoder(Uint8List payload, {int blockSize = defaultBlockSize})
      : payloadSize = payload.length,
        blockSize = blockSize,
        _blocks = _split(payload, blockSize),
        numBlocks = math.max(1, (payload.length / blockSize).ceil());

  static List<Uint8List> _split(Uint8List data, int blockSize) {
    final k = math.max(1, (data.length / blockSize).ceil());
    return List.generate(k, (i) {
      final start = i * blockSize;
      final end = math.min(start + blockSize, data.length);
      final block = Uint8List(blockSize); // zero-padded
      block.setRange(0, end - start, data, start);
      return block;
    });
  }

  /// Generate the next fountain frame.
  FountainFrame next() {
    final seed = _counter;
    _counter = (_counter >= 0x7FFFFFFF) ? 1 : _counter + 1;

    final degree = _sampleDegree(seed, numBlocks);
    final neighbors = _getNeighbors(seed, degree, numBlocks);

    final symbol = Uint8List(blockSize);
    for (final idx in neighbors) {
      final block = _blocks[idx];
      for (int i = 0; i < blockSize; i++) {
        symbol[i] ^= block[i];
      }
    }

    return FountainFrame(
      numBlocks: numBlocks,
      payloadSize: payloadSize,
      seed: seed,
      data: symbol,
    );
  }
}

// ── Decoder ─────────────────────────────────────────────────────────────────

/// Collects [FountainFrame]s and reconstructs the original payload via
/// belief propagation (iterative peeling decoder over GF(2)).
class FountainDecoder {
  final int numBlocks;
  final int blockSize;
  final int payloadSize;

  final List<Uint8List?> _decoded;
  int _decodedCount = 0;

  // Pending symbols stored as mutable (neighbors, data) pairs.
  // As blocks are decoded, they are XORed out of connected symbols and
  // the neighbor list is trimmed.
  final List<_Symbol> _pending = [];

  FountainDecoder({
    required this.numBlocks,
    required this.blockSize,
    required this.payloadSize,
  }) : _decoded = List<Uint8List?>.filled(numBlocks, null);

  bool get isComplete => _decodedCount >= numBlocks;

  /// How many source blocks have been recovered so far.
  int get decodedCount => _decodedCount;

  /// Progress in [0.0, 1.0].
  double get progress =>
      numBlocks == 0 ? 1.0 : _decodedCount / numBlocks;

  /// Feed a received frame into the decoder.
  /// Returns true when the payload can be reconstructed.
  bool addFrame(FountainFrame frame) {
    if (isComplete) return true;
    if (frame.numBlocks != numBlocks) return false; // wrong stream
    if (frame.data.length != blockSize) return false;

    final degree = _sampleDegree(frame.seed, numBlocks);
    final allNeighbors = _getNeighbors(frame.seed, degree, numBlocks);

    // Start with a copy of the symbol; XOR out already-decoded blocks.
    final symbolData = Uint8List.fromList(frame.data);
    final remaining = <int>[];

    for (final idx in allNeighbors) {
      final dec = _decoded[idx];
      if (dec != null) {
        for (int i = 0; i < blockSize; i++) {
          symbolData[i] ^= dec[i];
        }
      } else {
        remaining.add(idx);
      }
    }

    if (remaining.isEmpty) return isComplete; // symbol fully resolved

    if (remaining.length == 1) {
      _decodeBlock(remaining[0], symbolData);
    } else {
      _pending.add(_Symbol(remaining, symbolData));
    }

    _propagate();
    return isComplete;
  }

  void _decodeBlock(int index, Uint8List data) {
    if (_decoded[index] != null) return;
    _decoded[index] = Uint8List.fromList(data);
    _decodedCount++;

    // Use the saved copy, not `data` — when called from _propagate, `data` is
    // sym.data which still lives in _pending. The loop below would zero it on
    // the first hit (sym XOR sym = 0), corrupting every subsequent pending
    // symbol that needs to XOR out this block.
    final block = _decoded[index]!;
    for (final sym in _pending) {
      if (sym.neighbors.remove(index)) {
        for (int i = 0; i < blockSize; i++) {
          sym.data[i] ^= block[i];
        }
      }
    }
  }

  void _propagate() {
    bool changed = true;
    while (changed && !isComplete) {
      changed = false;
      for (int i = _pending.length - 1; i >= 0; i--) {
        final sym = _pending[i];
        if (sym.neighbors.isEmpty) {
          _pending.removeAt(i);
          continue;
        }
        if (sym.neighbors.length == 1) {
          _decodeBlock(sym.neighbors.first, sym.data);
          _pending.removeAt(i);
          changed = true;
        }
      }
    }
  }

  /// Reassemble the original payload from decoded blocks.
  /// Returns null if [isComplete] is false.
  Uint8List? reconstruct() {
    if (!isComplete) return null;
    final result = Uint8List(payloadSize);
    int pos = 0;
    for (int i = 0; i < numBlocks; i++) {
      final block = _decoded[i]!;
      final toCopy = math.min(blockSize, payloadSize - pos);
      if (toCopy <= 0) break;
      result.setRange(pos, pos + toCopy, block);
      pos += toCopy;
    }
    return result;
  }
}

class _Symbol {
  final List<int> neighbors; // mutable
  final Uint8List data;      // mutable (XOR'd in-place)
  _Symbol(this.neighbors, this.data);
}
