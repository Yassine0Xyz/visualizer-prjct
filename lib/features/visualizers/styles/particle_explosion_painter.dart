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
    if (count == 0 || minDimension <= 0) return;

    final energy = data.energy.clamp(0.0, 1.0).toDouble();
    final bass = data.bass.clamp(0.0, 1.0).toDouble();
    final maxRadius = minDimension * (0.27 + energy * 0.19) * config.intensity;
    final coreRadius = minDimension * (0.018 + bass * 0.025);

    // A restrained expanding shock ring gives the outward motion a clear origin.
    final ringProgress = (data.phase * 0.11) % 1.0;
    final ringRadius = coreRadius + (maxRadius - coreRadius) * ringProgress;
    final ringColor = colorAt(0.52, energy: energy, bass: bass);
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = ringColor.withValues(alpha: (1 - ringProgress) * (0.16 + energy * 0.20))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + energy * 1.4,
    );

    for (var band = 0; band < count; band++) {
      final value = data.values[band].clamp(0.0, 1.0).toDouble();
      final prior = data.previousValues[band].clamp(0.0, 1.0).toDouble();
      final onset = (value - prior).clamp(0.0, 0.32).toDouble();
      final angle = 2 * math.pi * band / count + data.phase * 0.12;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final color = colorAt(band / count, energy: energy, bass: bass);
      final burstRadius = maxRadius * (0.24 + value * 0.54 + bass * 0.08);
      final tailLength = minDimension * (0.012 + onset * 0.24 + value * 0.012);
      final tip = center + direction * burstRadius;
      final tail = tip - direction * tailLength;

      // Fine outward streaks appear on rising bands; brighter dots mark their tips.
      if (value > 0.045) {
        canvas.drawLine(
          tail,
          tip,
          Paint()
            ..color = color.withValues(
              alpha: (0.16 + value * 0.35 + onset * 1.2).clamp(0.0, 0.8).toDouble(),
            )
            ..strokeWidth = 0.7 + value * 1.1
            ..strokeCap = StrokeCap.round,
        );
      }

      final particleCount = value > 0.12 ? 2 : 1;
      for (var particle = 0; particle < particleCount; particle++) {
        final spread = particle == 0 ? 0.0 : (band.isEven ? 1 : -1) * 0.035;
        final particleAngle = angle + spread;
        final particleDirection = Offset(math.cos(particleAngle), math.sin(particleAngle));
        final radius = burstRadius * (particle == 0 ? 1.0 : 0.72);
        final position = center + particleDirection * radius;
        final dotRadius = 0.8 + value * 2.1 + onset * 3.0;
        final dotPaint = Paint()
          ..color = color.withValues(
            alpha: (0.30 + value * 0.55 + onset).clamp(0.0, 1.0).toDouble(),
          );
        if (config.glow && (value > 0.48 || onset > 0.045)) {
          dotPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.35);
        }
        canvas.drawCircle(position, dotRadius, dotPaint);
      }
    }

    final coreColor = colorAt(0.5, energy: energy, bass: bass);
    canvas.drawCircle(center, coreRadius * 1.8, Paint()..color = coreColor.withValues(alpha: 0.10 + energy * 0.10));
    canvas.drawCircle(center, coreRadius, glowingPaint(coreColor));
  }
}
