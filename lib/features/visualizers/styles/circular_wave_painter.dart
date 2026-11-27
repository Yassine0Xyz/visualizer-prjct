import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';

class CircularWavePainter extends VisualizerPainter {
  CircularWavePainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height);
    final n = data.values.length;
    if (n < 2 || minDim <= 0) return;
    final waveScale = config.intensity.clamp(0.5, 1.2).toDouble();

    // Circular wave spectrum
    final ringCount = 2;
    for (var ring = 0; ring < ringCount; ring++) {
      final t = ring / (ringCount - 1);
      final baseRadius = minDim * (0.16 + t * 0.13);

      final points = <Offset>[];
      final segments = n;

      for (var i = 0; i <= segments; i++) {
        final angle = 2 * math.pi * i / segments - math.pi / 2 + data.phase * 0.3;
        final v = data.values[i % n];
        final radius = baseRadius + v * minDim * 0.10 * waveScale;

        points.add(center + Offset(math.cos(angle), math.sin(angle)) * radius);
      }

      final color = colorAt(t, energy: data.energy, bass: data.bass);

      // Glow
      if (config.glow) {
        canvas.drawPath(
          smoothPath(points)..close(),
          Paint()
            ..color = color.withValues(alpha: 0.20 + data.energy * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 + data.bass * 3
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius),
        );
      }

      // Main wave
      canvas.drawPath(
        smoothPath(points)..close(),
        Paint()
          ..color = color.withValues(alpha: 0.50 + data.energy * 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + data.bass * 2,
      );

      // Fill
      canvas.drawPath(
        smoothPath(points)..close(),
        Paint()
          ..color = color.withValues(alpha: 0.06 + data.energy * 0.04)
          ..style = PaintingStyle.fill,
      );
    }

    // Spokes
    final spokeCount = 8;
    for (var i = 0; i < spokeCount; i++) {
      final angle = 2 * math.pi * i / spokeCount + data.phase * 0.2;
      final bandIdx = (i / spokeCount * n).round();
      final v = data.values[bandIdx.clamp(0, n - 1).toInt()];
      final innerR = minDim * 0.10;
      final outerR = minDim * (0.12 + v * 0.20);

      final inner = center + Offset(math.cos(angle), math.sin(angle)) * innerR;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * outerR;

      canvas.drawLine(
        inner, outer,
        Paint()
          ..color = colorAt(i / spokeCount, energy: data.energy)
              .withValues(alpha: 0.3 + v * 0.5)
          ..strokeWidth = 1.5 + v * 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Center
    canvas.drawCircle(
      center,
      3 + data.energy * 4,
      glowingPaint(colorAt(0.5, energy: data.energy)),
    );
  }
}
