import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../core/analysis/audio_frame.dart';

class VisualizerData extends ChangeNotifier {
  VisualizerData() {
    values = Float32List(AudioFrame.bandCount);
    targets = Float32List(AudioFrame.bandCount);
    previousValues = Float32List(AudioFrame.bandCount);
  }

  static const int bandCount = AudioFrame.bandCount;

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

  bool _stopped = true;

  void setStopped(bool stopped) => _stopped = stopped;

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
  ) {
    previousValues.setAll(0, values);
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

    var dirty = false;
    for (var i = 0; i < values.length; i++) {
      final v = _filter(values[i], targets[i], smoothness);
      if ((v - values[i]).abs() > 0.0003) dirty = true;
      values[i] = v;
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
