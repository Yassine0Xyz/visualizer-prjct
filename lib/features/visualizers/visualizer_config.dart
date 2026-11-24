import 'package:flutter/foundation.dart';

enum DuelMode {
  stereo,
  bassVsTreble,
}

class VisualizerConfig extends ChangeNotifier {
  DuelMode get duelMode => _duelMode;
  DuelMode _duelMode = DuelMode.stereo;
  set duelMode(DuelMode value) {
    if (_duelMode == value) return;
    _duelMode = value;
    notifyListeners();
  }

  double get sensitivity => _sensitivity;
  double _sensitivity = 1.4;
  set sensitivity(double v) {
    _sensitivity = v.clamp(0.2, 4.0).toDouble();
    notifyListeners();
  }

  double get smoothness => _smoothness;
  double _smoothness = 0.50;
  set smoothness(double v) {
    _smoothness = v.clamp(0.0, 0.95).toDouble();
    notifyListeners();
  }

  double get intensity => _intensity;
  double _intensity = 1.1;
  set intensity(double v) {
    _intensity = v.clamp(0.3, 2.5).toDouble();
    notifyListeners();
  }

  bool get glow => _glow;
  bool _glow = true;
  set glow(bool v) {
    _glow = v;
    notifyListeners();
  }

  double get glowRadius => _glowRadius;
  double _glowRadius = 12;
  set glowRadius(double v) {
    _glowRadius = v.clamp(0, 32).toDouble();
    notifyListeners();
  }

  bool get particles => _particles;
  bool _particles = true;
  set particles(bool v) {
    _particles = v;
    notifyListeners();
  }

  double get bassBoost => _bassBoost;
  double _bassBoost = 1.0;
  set bassBoost(double v) {
    _bassBoost = v.clamp(0.5, 3.0).toDouble();
    notifyListeners();
  }

  bool get mirror => _mirror;
  bool _mirror = false;
  set mirror(bool v) {
    _mirror = v;
    notifyListeners();
  }
}
