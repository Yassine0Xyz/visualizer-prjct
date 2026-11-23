import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';

class FluidBassPainter extends VisualizerPainter {
  FluidBassPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height);
    final bass = (data.bass * config.bassBoost).clamp(0.0, 1.0).toDouble();
    final energy = data.energy;

    // Liquid blobs responding to bass
    final blobCount = 5;
    for (var blob = 0; blob < blobCount; blob++) {
      final t = blob / (blobCount - 1);
      final baseRadius = minDim * (0.08 + t * 0.18);
      final blobBass = (bass * (0.7 + t * 0.3)).clamp(0.0, 1.0).toDouble();

      final points = <Offset>[];
      final segments = 20 + blob * 4;

      for (var i = 0; i <= segments; i++) {
        final angle = 2 * math.pi * i / segments;
        final wave1 = math.sin(angle * 3 + data.phase * 2 + blob) * 0.15;
        final wave2 = math.sin(angle * 5 - data.phase * 1.5 + blob * 2) * 0.10;
        final bassPulse = math.sin(data.beatPhase + blob * 0.8) * blobBass * 0.3;

        final radius = baseRadius * (1 + wave1 + wave2 + bassPulse);
        final x = center.dx + math.cos(angle) * radius;
        final y = center.dy + math.sin(angle) * radius * (0.8 + energy * 0.2);

        points.add(Offset(x, y));
      }

      final color = colorAt(t, energy: energy, bass: bass);
      final opacity = (0.15 + blobBass * 0.25 + energy * 0.10).clamp(0.0, 1.0).toDouble();

      if (config.glow) {
        canvas.drawPath(
          smoothPath(points)..close(),
          Paint()
            ..color = color.withValues(alpha: opacity * 0.4)
            ..style = PaintingStyle.fill
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * (0.8 + t * 0.4)),
        );
      }

      canvas.drawPath(
        smoothPath(points)..close(),
        Paint()
          ..color = color.withValues(alpha: opacity * 0.6)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        smoothPath(points)..close(),
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + bass * 2,
      );
    }

    // Center bass core
    final coreSize = minDim * 0.05 * (1 + bass * 1.2);
    canvas.drawCircle(
      center,
      coreSize,
      glowingPaint(colorAt(0.5, energy: energy, bass: bass)),
    );
  }
}
