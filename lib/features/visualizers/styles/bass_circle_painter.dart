import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class BassCirclePainter extends VisualizerPainter {
  BassCirclePainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    final center = size.center(Offset.zero);
    final minDimension = math.min(size.width, size.height);
    final count = data.values.length;
    if (count == 0) return;

    final bass = (data.bass * config.bassBoost).clamp(0.0, 1.0).toDouble();
    final baseRadius = minDimension * 0.17 * (1 + bass * 0.55);

    for (var ring = 0; ring < 4; ring++) {
      final radius = baseRadius + ring * minDimension * 0.065;
      final alpha = (0.52 - ring * 0.10 + data.energy * 0.12).clamp(0.08, 0.8).toDouble();
      final color = colorAt(ring / 3, energy: data.energy, bass: bass);
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring == 0 ? 2.5 + bass * 2 : 1.2;
      if (config.glow && ring == 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius);
      }
      canvas.drawCircle(center, radius, paint);
    }

    for (var i = 0; i < count; i++) {
      final angle = 2 * math.pi * i / count + data.phase * 0.25;
      final value = data.values[i].clamp(0.0, 1.0).toDouble();
      final innerRadius = baseRadius + minDimension * 0.025;
      final outerRadius = innerRadius + minDimension * (0.04 + value * 0.17 * config.intensity);
      final start = center + Offset(math.cos(angle), math.sin(angle)) * innerRadius;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * outerRadius;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = colorAt(i / count, energy: data.energy, bass: bass)
              .withValues(alpha: 0.42 + value * 0.5)
          ..strokeWidth = 1.2 + value * 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      center,
      minDimension * (0.045 + bass * 0.06),
      glowingPaint(colorAt(0.5, energy: data.energy, bass: bass)),
    );
  }
}
