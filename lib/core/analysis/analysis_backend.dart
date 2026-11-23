import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'spectrum_analyzer.dart';
import 'audio_frame.dart';

class AnalysisException implements Exception {
  AnalysisException(this.message);
  final String message;
  @override
  String toString() => 'AnalysisException: $message';
}

class AnalysisBackend {
  static const int _decodeSampleRate = SpectrumAnalyzer.sampleRate;

  Future<AnalysisResult> analyze(String filePath) async {
    final tempDir = await getTemporaryDirectory();
    final rawPath = p.join(tempDir.path, 'avl_v2_${DateTime.now().microsecondsSinceEpoch}.raw');

    try {
      final session = await FFmpegKit.execute(
        '-y -hide_banner -loglevel error '
        '-i "$filePath" -vn -ac 2 -ar $_decodeSampleRate -f s16le "$rawPath"',
      );
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getLogs();
        final tail = logs.isEmpty ? 'unknown error' : logs.last.getMessage();
        throw AnalysisException('FFmpeg decode failed: $tail');
      }

      final bytes = await File(rawPath).readAsBytes();
      if (bytes.length < 4) {
        throw AnalysisException('Decoded audio is empty');
      }
      return await compute(_analyzeBytes, bytes);
    } finally {
      try {
        final f = File(rawPath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
  }

  static AnalysisResult _analyzeBytes(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 4;
    final left = Float32List(sampleCount);
    final right = Float32List(sampleCount);
    final mono = Float32List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      left[i] = data.getInt16(i * 4, Endian.little) / 32768.0;
      right[i] = data.getInt16(i * 4 + 2, Endian.little) / 32768.0;
      mono[i] = (left[i] + right[i]) * 0.5;
    }
    final result = SpectrumAnalyzer.analyzePcm(mono);
    const waveformCount = 64;
    final frames = <AudioFrame>[];
    for (var frameIndex = 0; frameIndex < result.frames.length; frameIndex++) {
      final frame = result.frames[frameIndex];
      final start = frameIndex * SpectrumAnalyzer.hopSize;
      final waveL = Float32List(waveformCount);
      final waveR = Float32List(waveformCount);
      for (var sample = 0; sample < waveformCount; sample++) {
        final source = start + sample * SpectrumAnalyzer.fftSize ~/ waveformCount;
        waveL[sample] = left[source];
        waveR[sample] = right[source];
      }
      frames.add(AudioFrame(
        timeMs: frame.timeMs, bands: frame.bands, bass: frame.bass, mid: frame.mid,
        high: frame.high, energy: frame.energy, bassEnergy: frame.bassEnergy,
        midEnergy: frame.midEnergy, highEnergy: frame.highEnergy,
        waveformLeft: waveL, waveformRight: waveR,
      ));
    }
    return AnalysisResult(frames: frames, sampleRate: result.sampleRate, duration: result.duration);
  }
}
