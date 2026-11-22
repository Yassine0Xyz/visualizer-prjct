import 'dart:math' as math;
import 'dart:typed_data';

/// Iterative radix-2 FFT in pure Dart.
///
/// Operates in-place on pre-allocated [Float64List] buffers so the analyzer
/// never allocates inside its per-window loop. The trigonometric table is
/// precomputed once per instance.
class Fft {
  Fft(this.size) : assert(size >= 2 && (size & (size - 1)) == 0, 'FFT size must be a power of two') {
    _levels = _log2(size);
    final half = size >> 1;
    _cosTable = Float64List(half);
    _sinTable = Float64List(half);
    for (var i = 0; i < half; i++) {
      _cosTable[i] = math.cos(2 * math.pi * i / size);
      _sinTable[i] = math.sin(2 * math.pi * i / size);
    }
  }

  final int size;
  late final int _levels;
  late final Float64List _cosTable;
  late final Float64List _sinTable;

  static int _log2(int n) {
    var r = 0;
    while (n > 1) {
      n >>= 1;
      r++;
    }
    return r;
  }

  static int _reverseBits(int x, int bits) {
    var y = 0;
    for (var i = 0; i < bits; i++) {
      y = (y << 1) | (x & 1);
      x >>= 1;
    }
    return y;
  }

  /// In-place complex FFT. [re] and [im] must have exactly [size] elements.
  void transform(Float64List re, Float64List im) {
    final n = size;

    // Bit-reversal permutation.
    for (var i = 0; i < n; i++) {
      final j = _reverseBits(i, _levels);
      if (j > i) {
        var t = re[i];
        re[i] = re[j];
        re[j] = t;
        t = im[i];
        im[i] = im[j];
        im[j] = t;
      }
    }

    // Cooley-Tukey butterflies.
    for (var len = 2; len <= n; len <<= 1) {
      final half = len >> 1;
      final step = n ~/ len;
      for (var i = 0; i < n; i += len) {
        var k = 0;
        for (var j = i; j < i + half; j++, k += step) {
          final l = j + half;
          final cos = _cosTable[k];
          final sin = _sinTable[k];
          final tRe = re[l] * cos + im[l] * sin;
          final tIm = -re[l] * sin + im[l] * cos;
          re[l] = re[j] - tRe;
          im[l] = im[j] - tIm;
          re[j] += tRe;
          im[j] += tIm;
        }
      }
    }
  }
}

/// Cached Hann window of the given size.
Float64List hannWindow(int size) {
  final w = Float64List(size);
  for (var i = 0; i < size; i++) {
    w[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (size - 1));
  }
  return w;
}
