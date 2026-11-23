import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class ParticleExplosionPainter extends VisualizerPainter {
  ParticleExplosionPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    final center = size.center(Offset.zero);
    final minDimension = math.min(size.width, size.height);
    final count = data.values.length;
    if (count == 0) return;

    final energy = data.energy.clamp(0.0, 1.0).toDouble();
    final maxRadius = minDimension * (0.28 + energy * 0.20) * config.intensity;
    for (var band = 0; band < count; band++) {
      final value = data.values[band].clamp(0.0, 1.0).toDouble();
      final baseAngle = 2 * math.pi * band / count + data.phase * 0.22;
      final particlesPerBand = value > 0.08 ? 3 : 1;
      for (var particle = 0; particle < particlesPerBand; particle++) {
        final angle = baseAngle + (particle - 1) * 0.045;
        final radialProgress = ((0.24 + value * 0.62 + particle * 0.07 + energy * 0.12) % 1.0);
        final radius = maxRadius * radialProgress;
        final position = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        final dotRadius = 1.1 + value * 2.8 + energy * 1.2;
        final color = colorAt(band / count, energy: energy, bass: data.bass);
        final paint = Paint()..color = color.withValues(alpha: 0.38 + value * 0.55);
        if (config.glow && value > 0.45) {
          paint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.45);
        }
        canvas.drawCircle(position, dotRadius, paint);
      }
    }

    canvas.drawCircle(
      center,
      minDimension * (0.025 + energy * 0.035),
      glowingPaint(colorAt(0.5, energy: energy, bass: data.bass)),
    );
  }
}
