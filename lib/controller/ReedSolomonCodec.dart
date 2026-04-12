import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

// ── Reed-Solomon Erasure Codec ──────────────────────────────────────────────
//
// Simple implementation using generator matrix directly over GF(256).
// Any k of n shards can reconstruct the original data.
// Frame size: 500 bytes (fits QR v40-M ECC).

// ── GF(256) setup ────────────────────────────────────────────────────────────

final _expTable = List<int>.generate(512, (i) => 0);
final _logTable = List<int>.generate(256, (i) => 0);
var _gfInitialized = false;

void _ensureGfInit() {
  if (_gfInitialized) return;
  var x = 1;
  for (var i = 0; i < 255; i++) {
    _expTable[i] = x;
    _logTable[x] = i;
    x <<= 1;
    if (x >= 256) x ^= 0x11D; // Apply irreducible polynomial
    _expTable[i + 255] = x;
  }
  _gfInitialized = true;
}

int gfMul(int a, int b) {
  _ensureGfInit();
  return (a == 0 || b == 0)
      ? 0
      : _expTable[(_logTable[a] + _logTable[b]) % 255];
}

int gfInv(int a) => (a == 0)
    ? 0
    : (a == 1)
        ? 1
        : _expTable[255 - _logTable[a]];
int gfDiv(int a, int b) => gfMul(a, gfInv(b));

// ── Frame format ─────────────────────────────────────────────────────────────

const _magic = 0xCA;
// Header layout: magic(1) + numBlocks(2) + minBlocks(2) + payloadSize(4) + shardIndex(4) = 13 bytes
const _hdrSz = 13;

class RsFrame {
  final int numBlocks, minBlocks, payloadSize, shardIndex;
  final Uint8List data;

  const RsFrame({
    required this.numBlocks,
    required this.minBlocks,
    required this.payloadSize,
    required this.shardIndex,
    required this.data,
  });

  Uint8List toBytes() {
    final b = ByteData(_hdrSz + data.length);
    b.setUint8(0, _magic);
    b.setUint16(1, numBlocks, Endian.big);
    b.setUint16(3, minBlocks, Endian.big);
    b.setUint32(5, payloadSize, Endian.big);
    b.setUint32(9, shardIndex, Endian.big);
    b.buffer.asUint8List().setRange(_hdrSz, _hdrSz + data.length, data);
    return b.buffer.asUint8List();
  }

  String toQrData() => base64.encode(toBytes());

  static RsFrame? fromQrData(String s) {
    try {
      return fromBytes(base64.decode(s));
    } catch (_) {
      return null;
    }
  }

  static RsFrame? fromBytes(Uint8List b) {
    if (b.length <= _hdrSz || b[0] != _magic) return null;
    final v = ByteData.sublistView(b);
    final n = v.getUint16(1, Endian.big);
    final k = v.getUint16(3, Endian.big);
    final ps = v.getUint32(5, Endian.big);
    final si = v.getUint32(9, Endian.big);
    if (n == 0 || ps == 0 || si >= n || k <= 0 || k > n) return null;
    return RsFrame(
      numBlocks: n,
      minBlocks: k,
      payloadSize: ps,
      shardIndex: si,
      data: b.sublist(_hdrSz),
    );
  }
}

// ── Encoder ──────────────────────────────────────────────────────────────────

class RsEncoder {
  static const defaultBlockSize = int.fromEnvironment(
    'QR_BLOCK_SIZE',
    defaultValue: 500,
  );

  final int k, n, blockSize, payloadSize;
  late final List<Uint8List> _src;

  RsEncoder(Uint8List data, {int blockSize = defaultBlockSize})
      : payloadSize = data.length,
        blockSize = blockSize,
        k = math.max(1, (data.length / blockSize).ceil()),
        n = ((data.length / blockSize).ceil()) * 2 {
    // Split into k source shards
    _src = List.generate(k, (i) {
      final sh = Uint8List(blockSize);
      final start = i * blockSize;
      final cnt = math.min(blockSize, data.length - start);
      sh.setRange(0, cnt, data, start);
      return sh;
    });
  }

  List<RsFrame> encode() {
    final all = <Uint8List>[];
    final sz = blockSize;

    _ensureGfInit();

    for (var j = 0; j < n; j++) {
      final shard = Uint8List(sz);
      for (var b = 0; b < sz; b++) {
        var sum = 0;
        for (var i = 0; i < k; i++) {
          sum ^= gfMul(_expTable[(j * i) % 255], _src[i][b]);
        }
        shard[b] = sum;
      }
      all.add(shard);
    }

    return List.generate(
      n,
      (i) => RsFrame(
        numBlocks: n,
        minBlocks: k,
        payloadSize: payloadSize,
        shardIndex: i,
        data: all[i],
      ),
    );
  }
}

// ── Decoder ──────────────────────────────────────────────────────────────────

class RsDecoder {
  final int n, k, blockSize, payloadSize;
  final Map<int, Uint8List> _shards = {};

  RsDecoder({
    required this.n,
    required this.k,
    required this.blockSize,
    required this.payloadSize,
  });

  bool get isComplete => _shards.length >= k;
  int get receivedCount => _shards.length;
  double get progress => k == 0 ? 1.0 : _shards.length / k;

  bool addFrame(RsFrame f) {
    if (isComplete) return true;
    if (f.shardIndex < 0 || f.shardIndex >= n || f.data.length != blockSize)
      return false;
    _shards[f.shardIndex] = Uint8List.fromList(f.data);
    return isComplete;
  }

  Uint8List? reconstruct() {
    if (!isComplete) return null;

    _ensureGfInit();

    final idx = _shards.keys.take(k).toList()..sort();
    final sz = blockSize;

    final V = List.generate(
      k,
      (m) => List.generate(k, (i) => _expTable[(idx[m] * i) % 255]),
    );

    // Invert via Gauss-Jordan
    final aug = List.generate(k, (i) => List<int>.filled(k * 2, 0));
    for (var i = 0; i < k; i++) {
      for (var j = 0; j < k; j++) aug[i][j] = V[i][j];
      aug[i][k + i] = 1;
    }

    for (var col = 0; col < k; col++) {
      var piv = col;
      for (var r = col + 1; r < k; r++)
        if (aug[piv][col] == 0 && aug[r][col] != 0) piv = r;

      final tmp = aug[col];
      aug[col] = aug[piv];
      aug[piv] = tmp;

      final invP = gfInv(aug[col][col]);
      for (var j = col; j < k * 2; j++) aug[col][j] = gfMul(aug[col][j], invP);

      for (var r = 0; r < k; r++) {
        if (r != col && aug[r][col] != 0) {
          final f = aug[r][col];
          for (var j = col; j < k * 2; j++) aug[r][j] ^= gfMul(f, aug[col][j]);
        }
      }
    }

    final inv = List.generate(k, (i) => List.generate(k, (j) => aug[i][k + j]));

    // Reconstruct k source shards
    final src = List.generate(k, (_) => Uint8List(sz));
    for (var b = 0; b < sz; b++) {
      for (var i = 0; i < k; i++) {
        var sum = 0;
        for (var m = 0; m < k; m++) {
          sum ^= gfMul(inv[i][m], _shards[idx[m]]![b]);
        }
        src[i][b] = sum;
      }
    }

    // Assemble payload
    final out = Uint8List(payloadSize);
    var pos = 0;
    for (var i = 0; i < k && pos < payloadSize; i++) {
      final cnt = math.min(blockSize, payloadSize - pos);
      out.setRange(pos, pos + cnt, src[i]);
      pos += cnt;
    }
    return out;
  }
}
