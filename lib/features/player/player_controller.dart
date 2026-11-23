import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

import '../../core/analysis/analysis_backend.dart';
import '../../core/analysis/audio_frame.dart';
import '../../core/analysis/spectrum_analyzer.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/audio/audio_track.dart';
import '../visualizers/visualizer_config.dart';
import '../visualizers/visualizer_data.dart';
import '../visualizers/visualizer_style.dart';
import '../visualizers/visualizer_theme.dart';

class PlayerController extends ChangeNotifier {
  PlayerController({AnalysisBackend? backend})
      : _backend = backend ?? AnalysisBackend();

  final AnalysisBackend _backend;
  final AudioEngine engine = AudioEngine();
  final VisualizerData data = VisualizerData();
  final VisualizerConfig config = VisualizerConfig();

  VisualizerStyle style = VisualizerStyle.bars;
  VisualizerThemeData theme = VisualizerThemeData.presets.first;

  AudioTrack? track;
  List<AudioFrame> _frames = const [];
  double _frameIntervalMs = SpectrumAnalyzer.hopSize * 1000.0 / SpectrumAnalyzer.sampleRate;

  bool isLoading = false;
  bool analysisFailed = false;
  String statusMessage = 'Import an audio file to begin';

  StreamSubscription<PlayerState>? _stateSub;
  bool _playing = false;

  bool get hasTrack => track != null;

  Future<void> importAudio() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    final file = picked?.files.firstOrNull;
    final path = file?.path;
    if (path == null) return;
    await loadTrack(path, title: file!.name);
  }

  Future<void> loadTrack(String path, {String? title}) async {
    isLoading = true;
    data.clearHistory();
    analysisFailed = false;
    statusMessage = 'Decoding & analyzing audio...';
    notifyListeners();

    try {
      final result = await _backend.analyze(path);
      _frames = result.frames;
      _frameIntervalMs = result.frameIntervalMs;
    } on AnalysisException catch (e) {
      _frames = const [];
      analysisFailed = true;
      statusMessage = e.message;
    } catch (_) {
      _frames = const [];
      analysisFailed = true;
      statusMessage = 'Analysis unavailable for this file';
    }

    try {
      final duration = await engine.loadFile(path);
      track = AudioTrack(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title ?? p.basenameWithoutExtension(path),
        filePath: path,
        duration: duration ?? Duration.zero,
      );
      statusMessage = analysisFailed
          ? 'Playing (visualizers idle: analysis failed)'
          : 'Ready';
    } catch (e) {
      statusMessage = 'Playback failed: $e';
      track = null;
    }

    _stateSub ??= engine.playerStateStream.listen((state) {
      _playing = state.playing;
      data.setStopped(!_playing);
    });

    isLoading = false;
    notifyListeners();
  }

  Future<void> play() async {
    if (track == null) return;
    await engine.play();
  }

  Future<void> pause() => engine.pause();
  Future<void> stop() async {
    await engine.stop();
    data.setStopped(true);
  }

  Future<void> seek(Duration position) async {
    await engine.seek(position);
    pushFrameAt(position);
  }

  void tick() {
    if (_frames.isEmpty || track == null) return;
    pushFrameAt(engine.position);
  }

  void pushFrameAt(Duration position) {
    if (_frames.isEmpty) return;
    final t = position.inMilliseconds.toDouble();
    final idx = (t / _frameIntervalMs).clamp(0, _frames.length - 1).toDouble();
    final i0 = idx.floor().clamp(0, _frames.length - 1).toInt();
    final i1 = (i0 + 1).clamp(0, _frames.length - 1).toInt();
    final frac = (idx - i0).clamp(0.0, 1.0).toDouble();

    final f0 = _frames[i0];
    final f1 = _frames[i1];

    final bands = Float32List(AudioFrame.bandCount);
    final gain = config.sensitivity;
    for (var i = 0; i < bands.length; i++) {
      final raw = f0.bands[i] + (f1.bands[i] - f0.bands[i]) * frac;
      bands[i] = _softClip(raw * gain);
    }

    data.update(
      bands,
      _softClip(_lerp(f0.bass, f1.bass, frac) * gain),
      _softClip(_lerp(f0.mid, f1.mid, frac) * gain),
      _softClip(_lerp(f0.high, f1.high, frac) * gain),
      _softClip(_lerp(f0.energy, f1.energy, frac) * gain),
      _softClip(_lerp(f0.bassEnergy, f1.bassEnergy, frac) * gain),
      _softClip(_lerp(f0.midEnergy, f1.midEnergy, frac) * gain),
      _softClip(_lerp(f0.highEnergy, f1.highEnergy, frac) * gain),
      config.smoothness,
      _interpolateWave(f0.waveformLeft, f1.waveformLeft, frac),
      _interpolateWave(f0.waveformRight, f1.waveformRight, frac),
    );
  }

  static Float32List? _interpolateWave(Float32List? a, Float32List? b, double t) {
    if (a == null || b == null || a.length != b.length) return null;
    final out = Float32List(a.length);
    for (var i = 0; i < out.length; i++) {
      out[i] = a[i] + (b[i] - a[i]) * t;
    }
    return out;
  }
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _softClip(double x) {
    if (x <= 0) return 0;
    final v = x > 3 ? 1.0 : (x * (27 + x * x) / (27 + 9 * x * x));
    return v.clamp(0.0, 1.0).toDouble();
  }

  void selectStyle(VisualizerStyle s) {
    style = s;
    notifyListeners();
  }

  void selectTheme(VisualizerThemeData t) {
    theme = t;
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    engine.dispose();
    config.dispose();
    data.dispose();
    super.dispose();
  }
}
