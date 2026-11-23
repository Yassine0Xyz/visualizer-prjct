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
    double duelLeftTarget = 0,
    double duelRightTarget = 0,
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

    bass = _filter(bass, bassT, smoothness);
    mid = _filter(mid, midT, smoothness);
    high = _filter(high, highT, smoothness);
    energy = _filter(energy, energyT, smoothness);
    bassEnergy = _filter(bassEnergy, bassEnergyT, smoothness);
    midEnergy = _filter(midEnergy, midEnergyT, smoothness);
    highEnergy = _filter(highEnergy, highEnergyT, smoothness);
    duelLeftEnergy = _filter(duelLeftEnergy, duelLeftTarget, smoothness);
    duelRightEnergy = _filter(duelRightEnergy, duelRightTarget, smoothness);

    var dirty = false;
    for (var i = 0; i < values.length; i++) {
      final v = _filter(values[i], targets[i], smoothness);
      if ((v - values[i]).abs() > 0.0003) dirty = true;
      values[i] = v;
    }
    if (!_stopped && (_history.isEmpty || _history.last.asMap().entries.any((e) => (e.value - values[e.key]).abs() > 0.025))) {
      _history.add(Float32List.fromList(values));
      if (_history.length > historyCapacity) _history.removeAt(0);
    }
    if (dirty || !_stopped) notifyListeners();
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
