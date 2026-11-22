import 'dart:typed_data';

import 'package:audio_visualizer_lab/core/analysis/fft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fft', () {
    test('transforms an impulse into a flat spectrum', () {
      final real = Float64List.fromList([1, 0, 0, 0, 0, 0, 0, 0]);
      final imaginary = Float64List(8);

      Fft(8).transform(real, imaginary);

      expect(real, everyElement(1));
      expect(imaginary, everyElement(0));
    });

    test('Hann window reaches zero at both edges', () {
      final window = hannWindow(5);

      expect(window.first, closeTo(0, 1e-12));
      expect(window.last, closeTo(0, 1e-12));
      expect(window[2], closeTo(1, 1e-12));
    });
  });
}
