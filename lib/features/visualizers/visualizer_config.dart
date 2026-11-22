import 'package:flutter/foundation.dart';

/// User-tunable rendering settings, independent of any visualizer style.
class VisualizerConfig extends ChangeNotifier {
  /// Gain applied to band values (0.2 .. 3.0).
  double get sensitivity => _sensitivity;
  double _sensitivity = 1.3;
  set sensitivity(double v) {
    _sensitivity = v.clamp(0.2, 3.0);
    notifyListeners();
  }

  /// 0 = sharp/snappy, 1 = heavy smoothing.
  double get smoothness => _smoothness;
  double _smoothness = 0.55;
  set smoothness(double v) {
    _smoothness = v.clamp(0.0, 0.95);
    notifyListeners();
  }

  /// Global amplitude scale (0.3 .. 2.0).
  double get intensity => _intensity;
  double _intensity = 1.0;
  set intensity(double v) {
    _intensity = v.clamp(0.3, 2.0);
    notifyListeners();
  }

  bool get glow => _glow;
  bool _glow = true;
  set glow(bool v) {
    _glow = v;
    notifyListeners();
  }

  double get glowRadius => _glowRadius;
  double _glowRadius = 10;
  set glowRadius(double v) {
    _glowRadius = v.clamp(0, 24);
    notifyListeners();
  }
}
