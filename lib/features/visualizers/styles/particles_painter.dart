import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';
import '../visualizer_data.dart';

/// Precomputed particle seed data. Cached per particle count so per-frame
/// painting allocates nothing here.
class ParticleField {
  ParticleField._(this.count) {
    final rand = math.Random(7);
    bandIndex = List<int>.generate(count, (i) => rand.nextInt(VisualizerData.bandCount));
    angle = List<double>.generate(count, (i) => rand.nextDouble() * 2 * math.pi);
    radius = List<double>.generate(count, (i) => math.sqrt(rand.nextDouble()));
    size = List<double>.generate(count, (i) => 0.5 + rand.nextDouble() * 1.8);
    drift = List<double>.generate(count, (i) => 0.4 + rand.nextDouble() * 1.2);
  }

  final int count;
  late final List<int> bandIndex;
  late final List<double> angle;
  late final List<double> radius;
  late final List<double> size;
  late final List<double> drift;

  static const int defaultCount = 220;
  static final Map<int, ParticleField> _cache = {};

  factory ParticleField.get(int count) =>
      _cache.putIfAbsent(count, () => ParticleField._(count));
}

/// A field of particles orbiting the center, pushed outward by the spectrum.
class ParticlesPainter extends VisualizerPainter {
  ParticlesPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height);
    final field = ParticleField.get(ParticleField.defaultCount);

    final blurPaint = config.glow
        ? (Paint()
          ..color = Colors.white
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.7))
        : null;

    for (var i = 0; i < field.count; i++) {
      final band = data.values[field.bandIndex[i]];
      final angle = field.angle[i] + data.phase * field.drift[i];
      final r = (0.12 + field.radius[i] * 0.45 + band * 0.28) * minDim * 0.9;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * r;
      final dotSize = field.size[i] * (0.8 + band * 2.2 + data.energy);
      final color = colorAt(field.bandIndex[i] / (VisualizerData.bandCount - 1))
          .withOpacity((0.20 + band * 0.65).clamp(0.0, 1.0));

      if (blurPaint != null && band > 0.25) {
        canvas.drawCircle(pos, dotSize * 2.2, blurPaint..color = color.withOpacity(0.4));
      }
      canvas.drawCircle(pos, dotSize, Paint()..color = color);
    }
  }
}
