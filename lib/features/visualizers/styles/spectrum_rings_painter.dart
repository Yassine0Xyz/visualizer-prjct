import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';

class SpectrumRingsPainter extends VisualizerPainter {
  SpectrumRingsPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height);
    final n = data.values.length;
    if (n < 2 || minDim <= 0) return;
    final spectrumScale = config.intensity.clamp(0.5, 1.2).toDouble();

    // Rotating spectrum as concentric rings
    final ringCount = 5;
    for (var ring = 0; ring < ringCount; ring++) {
      final t = ring / (ringCount - 1);
      final baseRadius = minDim * (0.10 + t * 0.22);
      final rotation = data.phase * (ring.isEven ? 1 : -1) * (0.5 + t * 0.3);

      final points = <Offset>[];
      final segments = 32 + ring * 8;

      for (var i = 0; i <= segments; i++) {
        final angle = 2 * math.pi * i / segments + rotation;
        final bandIdx = (i / segments * n * 0.5 + ring * n * 0.1).round() % n;
        final v = data.values[bandIdx];
        final radius = baseRadius * (1 + v * 0.30 * spectrumScale);

        points.add(center + Offset(math.cos(angle), math.sin(angle)) * radius);
      }

      final color = colorAt(t, energy: data.energy, bass: data.bass);
      final opacity = (0.20 + t * 0.30 + data.energy * 0.15).clamp(0.0, 1.0).toDouble();

      if (config.glow) {
        canvas.drawPath(
          smoothPath(points)..close(),
          Paint()
            ..color = color.withValues(alpha: opacity * 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius),
        );
      }

      canvas.drawPath(
        smoothPath(points)..close(),
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Fill with low opacity
      canvas.drawPath(
        smoothPath(points)..close(),
        Paint()
          ..color = color.withValues(alpha: opacity * 0.08)
          ..style = PaintingStyle.fill,
      );
    }

    // Center element
    final centerPulse = minDim * 0.04 * (1 + data.bass * config.bassBoost);
    canvas.drawCircle(
      center,
      centerPulse,
      glowingPaint(colorAt(0.5, energy: data.energy)),
    );
  }
}
