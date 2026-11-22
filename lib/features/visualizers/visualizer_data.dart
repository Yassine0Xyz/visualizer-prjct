import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'audio_frame.dart';

/// Live, smoothed visualizer state.
///
/// Updated once per display frame by the player controller, consumed directly
/// by painters. Holds the per-band values plus derived aggregates and a
/// beat-driven [phase] used for rotation/drift in radial styles.
///
/// Smoothing uses asymmetric exponential filtering (fast attack, slow
/// release) so visuals feel punchy but never snap to zero.
class VisualizerData extends ChangeNotifier {
  VisualizerData() {
    values = Float32List(AudioFrame.bandCount);
    targets = Float32List(AudioFrame.bandCount);
  }

  static const int bandCount = AudioFrame.bandCount;

  late final Float32List values;
  late final Float32List targets;

  double bass = 0;
  double mid = 0;
  double high = 0;
  double energy = 0;

  /// Accumulated rotation, advanced by energy. Used by circular styles.
  double phase = 0;

  bool _stopped = true;

  void setStopped(bool stopped) => _stopped = stopped;

  /// Push a new analysis target set. [smoothness] in 0..0.95.
  void update(
    Float32List newTargets,
    double bassT,
    double midT,
    double highT,
    double energyT,
    double smoothness,
  ) {
    targets.setAll(0, newTargets);

    if (!_stopped) {
      phase += 0.0035 + energyT * 0.02;
    }

    bass = _filter(bass, bassT, smoothness);
    mid = _filter(mid, midT, smoothness);
    high = _filter(high, highT, smoothness);
    energy = _filter(energy, energyT, smoothness);

    var dirty = false;
    for (var i = 0; i < values.length; i++) {
      final v = _filter(values[i], targets[i], smoothness);
      if ((v - values[i]).abs() > 0.0004) dirty = true;
      values[i] = v;
    }
    if (dirty || !_stopped) notifyListeners();
  }

  double _filter(double current, double target, double smoothness) {
    if (_stopped) {
      // Fast fall to silence when stopped.
      return current + (0 - current) * 0.18;
    }
    final s = smoothness.clamp(0.0, 0.95);
    // Fast attack, slower release: feels punchy yet fluid.
    final k = target > current
        ? _lerp(0.72, 0.20, s)
        : _lerp(0.38, 0.06, s);
    return current + (target - current) * k;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
