import 'dart:typed_data';

import 'package:audio_visualizer_lab/core/analysis/audio_frame.dart';
import 'package:audio_visualizer_lab/core/analysis/spectrum_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpectrumAnalyzer', () {
    test('returns no frames when PCM is shorter than one FFT window', () {
      final result = SpectrumAnalyzer.analyzePcm(
        Float32List(SpectrumAnalyzer.fftSize - 1),
      );

      expect(result.frames, isEmpty);
      expect(result.sampleRate, SpectrumAnalyzer.sampleRate);
    });

    test('analyzes silence into finite, bounded bands', () {
      final pcm = Float32List(SpectrumAnalyzer.fftSize + SpectrumAnalyzer.hopSize);
      final result = SpectrumAnalyzer.analyzePcm(pcm);

      expect(result.frames, hasLength(2));
      for (final frame in result.frames) {
        expect(frame.bands, hasLength(AudioFrame.bandCount));
        expect(frame.energy, inInclusiveRange(0, 1));
        expect(frame.bass, inInclusiveRange(0, 1));
        expect(frame.mid, inInclusiveRange(0, 1));
        expect(frame.high, inInclusiveRange(0, 1));
        expect(frame.bands, everyElement(inInclusiveRange(0, 1)));
      }
    });
  });
}
