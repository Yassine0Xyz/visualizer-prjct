import 'dart:math' as math;
import 'dart:typed_data';

import 'audio_frame.dart';
import 'fft.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.frames,
    required this.sampleRate,
    required this.duration,
  });

  final List<AudioFrame> frames;
  final int sampleRate;
  final Duration duration;

  double get frameIntervalMs => 1000.0 * SpectrumAnalyzer.hopSize / sampleRate;
}

class SpectrumAnalyzer {
  const SpectrumAnalyzer._();

  static const int sampleRate = 22050;
  static const int fftSize = 2048;
  static const int hopSize = 1024;
  static const int bandCount = AudioFrame.bandCount;

  static const double _minFreq = 20;
  static const double _peakDecay = 0.9985;
  static const double _peakFloor = 1e-7;

  static AnalysisResult analyzePcm(Float32List pcm) {
    final fft = Fft(fftSize);
    final window = hannWindow(fftSize);
    final re = Float64List(fftSize);
    final im = Float64List(fftSize);

    final bandEdges = _logSpacedEdges(_minFreq, sampleRate / 2, bandCount + 1);
    final bandBins = List<int>.generate(bandCount + 1, (i) {
      final bin = (bandEdges[i] * fftSize / sampleRate).floor();
      return bin.clamp(0, fftSize ~/ 2).toInt();
    });

    final peaks = Float64List(bandCount);
    for (var i = 0; i < bandCount; i++) {
      peaks[i] = _peakFloor;
    }

    final frames = <AudioFrame>[];
    final mags = Float64List(bandCount);

    for (var start = 0; start + fftSize <= pcm.length; start += hopSize) {
      for (var i = 0; i < fftSize; i++) {
        re[i] = pcm[start + i] * window[i];
        im[i] = 0;
      }
      fft.transform(re, im);

      for (var b = 0; b < bandCount; b++) {
        final lo = bandBins[b];
        var hi = bandBins[b + 1];
        if (hi <= lo) hi = lo + 1;
        var power = 0.0;
        for (var k = lo; k < hi; k++) {
          power += re[k] * re[k] + im[k] * im[k];
        }
        power /= (hi - lo) * fftSize * fftSize;
        mags[b] = math.sqrt(power);
      }

      for (var b = 0; b < bandCount; b++) {
        if (mags[b] > peaks[b]) {
          peaks[b] = mags[b];
        } else {
          peaks[b] = math.max(peaks[b] * _peakDecay, _peakFloor);
        }
      }

      final bands = Float32List(bandCount);
      var bassSum = 0.0, midSum = 0.0, highSum = 0.0;
      var bassEnergySum = 0.0, midEnergySum = 0.0, highEnergySum = 0.0;
      var bassN = 0, midN = 0, highN = 0;

      for (var b = 0; b < bandCount; b++) {
        var v = (mags[b] / (peaks[b] + _peakFloor)).clamp(0.0, 1.0).toDouble();
        v = math.pow(v, 0.60).toDouble();
        bands[b] = v;
        final freq = bandEdges[b];
        if (freq < 200) {
          bassSum += v; bassEnergySum += mags[b]; bassN++;
        } else if (freq < 3000) {
          midSum += v; midEnergySum += mags[b]; midN++;
        } else {
          highSum += v; highEnergySum += mags[b]; highN++;
        }
      }

      final bass = bassN == 0 ? 0.0 : bassSum / bassN;
      final mid = midN == 0 ? 0.0 : midSum / midN;
      final high = highN == 0 ? 0.0 : highSum / highN;
      final energy = (0.45 * bass + 0.35 * mid + 0.20 * high)
          .clamp(0.0, 1.0)
          .toDouble();

      frames.add(AudioFrame(
        timeMs: start * 1000.0 / sampleRate,
        bands: bands,
        bass: bass,
        mid: mid,
        high: high,
        energy: energy,
        bassEnergy: bassN == 0 ? 0.0 : bassEnergySum / bassN,
        midEnergy: midN == 0 ? 0.0 : midEnergySum / midN,
        highEnergy: highN == 0 ? 0.0 : highEnergySum / highN,
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
