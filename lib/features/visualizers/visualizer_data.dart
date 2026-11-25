import 'package:flutter/foundation.dart';

import '../../core/analysis/audio_frame.dart';

class VisualizerData extends ChangeNotifier {
  VisualizerData() {
    values = Float32List(AudioFrame.bandCount);
    targets = Float32List(AudioFrame.bandCount);
    previousValues = Float32List(AudioFrame.bandCount);
  }

  static const int bandCount = AudioFrame.bandCount;
  static const int historyCapacity = 120;
  final List<Float32List> _history = <Float32List>[];
  List<Float32List> get history => List<Float32List>.unmodifiable(_history);

  late final Float32List values;
  late final Float32List targets;
  late final Float32List previousValues;

  double bass = 0;
  double mid = 0;
  double high = 0;
  double energy = 0;
  double bassEnergy = 0;
  double midEnergy = 0;
  double highEnergy = 0;

  double phase = 0;
  double beatPhase = 0;
  double duelLeftEnergy = 0;
  double duelRightEnergy = 0;
  double fighterClash = 0;
  double fighterClashProgress = 0;
  int _bassOnsetWindow = 0;
  int _trebleOnsetWindow = 0;
  int _fighterClashCooldown = 0;
  int _fighterClashFrame = -1;
  Float32List waveformLeft = Float32List(64);
  Float32List waveformRight = Float32List(64);

  bool _stopped = true;

  void setStopped(bool stopped) => _stopped = stopped;
  void clearHistory() => _history.clear();

  void update(
    Float32List newTargets,
    double bassT,
    double midT,
    double highT,
    double energyT,
    double bassEnergyT,
    double midEnergyT,
    double highEnergyT,
    double smoothness,
    Float32List? waveLeft,
    Float32List? waveRight,
    double duelLeftTarget,
    double duelRightTarget,
  ) {
    previousValues.setAll(0, values);
    if (waveLeft != null && waveRight != null) {
      waveformLeft = Float32List.fromList(waveLeft);
      waveformRight = Float32List.fromList(waveRight);
    }
    targets.setAll(0, newTargets);

    if (!_stopped) {
      phase += 0.004 + energyT * 0.025;
      beatPhase += 0.008 + bassT * 0.04;
    }

    final previousBass = bass;
    final previousHigh = high;
    final previousClash = fighterClash;
    bass = _filter(bass, bassT, smoothness);
    mid = _filter(mid, midT, smoothness);
    high = _filter(high, highT, smoothness);
    energy = _filter(energy, energyT, smoothness);
    bassEnergy = _filter(bassEnergy, bassEnergyT, smoothness);
    midEnergy = _filter(midEnergy, midEnergyT, smoothness);
    highEnergy = _filter(highEnergy, highEnergyT, smoothness);
    duelLeftEnergy = _filter(duelLeftEnergy, duelLeftTarget, smoothness);
    duelRightEnergy = _filter(duelRightEnergy, duelRightTarget, smoothness);

    // A clash is armed only by fresh rises in both the bass and treble sources
    // inside a short coincidence window. The refractory period prevents rapid
    // retriggering; its animation advances with existing audio updates only.
    if (!_stopped) {
      if (bass - previousBass > 0.045 && bass > 0.28) {
        _bassOnsetWindow = 10;
      } else if (_bassOnsetWindow > 0) {
        _bassOnsetWindow--;
      }
      if (high - previousHigh > 0.045 && high > 0.30) {
        _trebleOnsetWindow = 10;
      } else if (_trebleOnsetWindow > 0) {
        _trebleOnsetWindow--;
      }
      if (_fighterClashCooldown > 0) _fighterClashCooldown--;
      if (_bassOnsetWindow > 0 &&
          _trebleOnsetWindow > 0 &&
          _fighterClashCooldown == 0) {
        _fighterClashFrame = 0;
        fighterClash = 0;
        fighterClashProgress = 0;
        _fighterClashCooldown = 72;
        _bassOnsetWindow = 0;
        _trebleOnsetWindow = 0;
      }
      _advanceFighterClash();
    } else {
      _bassOnsetWindow = 0;
      _trebleOnsetWindow = 0;
      _fighterClashFrame = -1;
      fighterClashProgress = 0;
      fighterClash *= 0.72;
    }

    var dirty = false;
    for (var i = 0; i < values.length; i++) {
      final v = _filter(values[i], targets[i], smoothness);
      if ((v - values[i]).abs() > 0.0003) dirty = true;
      values[i] = v;
    }
    if (!_stopped &&
        (_history.isEmpty ||
            _history.last.asMap().entries.any(
              (e) => (e.value - values[e.key]).abs() > 0.025,
            ))) {
      _history.add(Float32List.fromList(values));
      if (_history.length > historyCapacity) _history.removeAt(0);
    }
    final clashDirty = (fighterClash - previousClash).abs() > 0.0003;
    if (dirty || clashDirty || !_stopped) notifyListeners();
  }

  void _advanceFighterClash() {
    if (_fighterClashFrame < 0) {
      fighterClash = 0;
      fighterClashProgress = 0;
      return;
    }

    const durationFrames = 40;
    _fighterClashFrame++;
    final progress =
        (_fighterClashFrame / durationFrames).clamp(0.0, 1.0).toDouble();
    fighterClashProgress = progress;

    // 0.00–0.34: approach; 0.34–0.46: impact; 0.46–1.00: recoil.
    if (progress < 0.34) {
      final t = progress / 0.34;
      fighterClash = 0.78 * t * t * (3 - 2 * t);
    } else if (progress < 0.46) {
      final t = (progress - 0.34) / 0.12;
      fighterClash = 0.78 + 0.22 * t;
    } else {
      final t = ((progress - 0.46) / 0.54).clamp(0.0, 1.0).toDouble();
      final eased = t * t * (3 - 2 * t);
      fighterClash = 1 - eased;
    }

    if (_fighterClashFrame >= durationFrames) {
      _fighterClashFrame = -1;
      fighterClash = 0;
      fighterClashProgress = 0;
    }
  }

  double _filter(double current, double target, double smoothness) {
    if (_stopped) {
      return current + (0 - current) * 0.15;
    }
    final s = smoothness.clamp(0.0, 0.95).toDouble();
    final k = target > current
        ? _lerp(0.75, 0.22, s)
        : _lerp(0.40, 0.07, s);
    return current + (target - current) * k;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
