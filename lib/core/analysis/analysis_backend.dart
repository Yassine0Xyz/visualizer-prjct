import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'spectrum_analyzer.dart';

class AnalysisException implements Exception {
  AnalysisException(this.message);
  final String message;
  @override
  String toString() => 'AnalysisException: $message';
}

/// Decodes an audio file to mono 22050 Hz PCM with FFmpeg, then runs the
/// pure-Dart [SpectrumAnalyzer] in a background isolate.
class AnalysisBackend {
  static const int _decodeSampleRate = SpectrumAnalyzer.sampleRate;

  Future<AnalysisResult> analyze(String filePath) async {
    final tempDir = await getTemporaryDirectory();
    final rawPath = p.join(tempDir.path, 'avl_${DateTime.now().microsecondsSinceEpoch}.raw');

    try {
      final session = await FFmpegKit.execute(
        '-y -hide_banner -loglevel error '
        '-i "$filePath" -vn -ac 1 -ar $_decodeSampleRate -f s16le "$rawPath"',
      );
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getLogs();
        final tail = logs.isEmpty ? 'unknown error' : logs.last.getMessage();
        throw AnalysisException('FFmpeg decode failed: $tail');
      }

      final bytes = await File(rawPath).readAsBytes();
      if (bytes.length < 2) {
        throw AnalysisException('Decoded audio is empty');
      }
      return await compute(_analyzeBytes, bytes);
    } finally {
      // Best-effort cleanup of the temp PCM file.
      try {
        final f = File(rawPath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {/* ignore */}
    }
  }

  /// Runs in a separate isolate; must be a top-level or static function.
  static AnalysisResult _analyzeBytes(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 2;
    final pcm = Float32List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      pcm[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return SpectrumAnalyzer.analyzePcm(pcm);
  }
}
