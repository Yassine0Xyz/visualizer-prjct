import 'dart:math' as math;
import 'dart:typed_data';

import 'audio_frame.dart';
import 'fft.dart';

/// Result of a full-track analysis.
class AnalysisResult {
  const AnalysisResult({
    required this.frames,
    required this.sampleRate,
    required this.duration,
  });

  /// One frame per [SpectrumAnalyzer.hopSize] samples.
  final List<AudioFrame> frames;

  /// Sample rate of the decoded PCM used for analysis.
  final int sampleRate;

  final Duration duration;

  /// Milliseconds between consecutive frames.
  double get frameIntervalMs => 1000.0 * SpectrumAnalyzer.hopSize / sampleRate;
}

/// Pure-Dart spectrum analysis pipeline.
///
/// Decoded mono PCM -> overlapping Hann windows -> radix-2 FFT -> average
/// power per log-spaced frequency band -> adaptive per-band peak
/// normalization -> [AudioFrame] stream.
///
/// Runs entirely in Dart (no native analysis code); it is normally executed
/// inside a [compute] isolate so the UI never janks.
class SpectrumAnalyzer {
  const SpectrumAnalyzer._();

  static const int sampleRate = 22050;
  static const int fftSize = 2048;
  static const int hopSize = 1024; // ~21.7 ms between frames @ 22050 Hz
  static const int bandCount = AudioFrame.bandCount;

  static const double _minFreq = 30;
  static const double _peakDecay = 0.9992;
  static const double _peakFloor = 1e-7;

  /// Top-level entry point usable with `compute()`.
  static AnalysisResult analyzePcm(Float32List pcm) {
    final fft = Fft(fftSize);
    final window = hannWindow(fftSize);
    final re = Float64List(fftSize);
    final im = Float64List(fftSize);

    final bandEdges = _logSpacedEdges(_minFreq, sampleRate / 2, bandCount + 1);
    // Convert frequencies to FFT bin indices.
    final bandBins = List<int>.generate(bandCount + 1, (i) {
      final bin = (bandEdges[i] * fftSize / sampleRate).floor();
      return bin.clamp(0, fftSize ~/ 2);
    });

    final peaks = Float64List(bandCount);
    for (var i = 0; i < bandCount; i++) {
      peaks[i] = _peakFloor;
    }

    final frames = <AudioFrame>[];
    final mags = Float64List(bandCount);

    for (var start = 0; start + fftSize <= pcm.length; start += hopSize) {
      // Windowed copy into the FFT buffers.
      for (var i = 0; i < fftSize; i++) {
        re[i] = pcm[start + i] * window[i];
        im[i] = 0;
      }
      fft.transform(re, im);

      // Average power per band -> magnitude.
      for (var b = 0; b < bandCount; b++) {
        final lo = bandBins[b];
        var hi = bandBins[b + 1];
        if (hi <= lo) hi = lo + 1;
        var power = 0.0;
        for (var k = lo; k < hi; k++) {
          power += re[k] * re[k] + im[k] * im[k];
        }
        power /= (hi - lo) * fftSize * fftSize; // scale with window gain
        mags[b] = math.sqrt(power);
      }

      // Per-band adaptive normalization: fast attack, slow release.
      // This keeps quiet sections of a song visually alive.
      for (var b = 0; b < bandCount; b++) {
        if (mags[b] > peaks[b]) {
          peaks[b] = mags[b];
        } else {
          peaks[b] = math.max(peaks[b] * _peakDecay, _peakFloor);
        }
      }

      final bands = Float32List(bandCount);
      var bassSum = 0.0, midSum = 0.0, highSum = 0.0;
      var bassN = 0, midN = 0, highN = 0;
      for (var b = 0; b < bandCount; b++) {
        var v = (mags[b] / (peaks[b] + _peakFloor)).clamp(0.0, 1.0);
        v = math.pow(v, 0.65).toDouble(); // perceptual lift
        bands[b] = v;
        final freq = bandEdges[b];
        if (freq < 250) {
          bassSum += v;
          bassN++;
        } else if (freq < 4000) {
          midSum += v;
          midN++;
        } else {
          highSum += v;
          highN++;
        }
      }

      final bass = bassN == 0 ? 0.0 : bassSum / bassN;
      final mid = midN == 0 ? 0.0 : midSum / midN;
      final high = highN == 0 ? 0.0 : highSum / highN;
      final energy = (0.5 * bass + 0.35 * mid + 0.15 * high).clamp(0.0, 1.0);

      frames.add(AudioFrame(
        timeMs: start * 1000.0 / sampleRate,
        bands: bands,
        bass: bass,
        mid: mid,
        high: high,
        energy: energy,
      ));
    }

    final durationMs = pcm.length * 1000.0 / sampleRate;
    return AnalysisResult(
      frames: frames,
      sampleRate: sampleRate,
      duration: Duration(milliseconds: durationMs.round()),
    );
  }

  static List<double> _logSpacedEdges(double min, double max, int count) {
    final ratio = math.pow(max / min, 1 / (count - 1)).toDouble();
    final edges = List<double>.generate(count, (i) => min * math.pow(ratio, i).toDouble());
    edges[count - 1] = max;
    return edges;
  }
}
