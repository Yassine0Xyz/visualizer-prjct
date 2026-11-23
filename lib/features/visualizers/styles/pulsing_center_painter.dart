import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class PulsingCenterPainter extends VisualizerPainter {
  PulsingCenterPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    final center = size.center(Offset.zero);
    final minDimension = math.min(size.width, size.height);
    final count = data.values.length;
    if (count == 0) return;

    final pulse = (0.5 + 0.5 * math.sin(data.beatPhase)).clamp(0.0, 1.0).toDouble();
    final coreRadius = minDimension * (0.045 + data.bass * config.bassBoost * 0.055);
    canvas.drawCircle(
      center,
      coreRadius,
      glowingPaint(colorAt(0.5, energy: data.energy, bass: data.bass)),
    );

    const ringCount = 6;
    for (var ring = 0; ring < ringCount; ring++) {
      final ringT = ring / (ringCount - 1);
      final radius = coreRadius + minDimension * (0.06 + ringT * 0.31) + pulse * minDimension * 0.018;
      final alpha = (0.58 - ringT * 0.42 + data.energy * 0.18).clamp(0.08, 0.85).toDouble();
      final paint = Paint()
        ..color = colorAt(ringT, energy: data.energy, bass: data.bass).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + (1 - ringT) * 1.8;
      if (config.glow && ring < 2) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.7);
      }
      canvas.drawCircle(center, radius, paint);
    }

    for (var i = 0; i < count; i++) {
      final value = data.values[i].clamp(0.0, 1.0).toDouble();
      final angle = 2 * math.pi * i / count + data.phase * 0.16;
      final innerRadius = coreRadius + minDimension * 0.06;
      final outerRadius = innerRadius + minDimension * (0.025 + value * 0.20 * config.intensity);
      final start = center + Offset(math.cos(angle), math.sin(angle)) * innerRadius;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * outerRadius;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = colorAt(i / count, energy: data.energy, bass: data.bass)
              .withValues(alpha: 0.28 + value * 0.66)
          ..strokeWidth = 1 + value * 1.7
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
