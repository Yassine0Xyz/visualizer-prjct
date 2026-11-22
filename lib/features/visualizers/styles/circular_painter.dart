import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// Frequency bars arranged radially around a ring, rotating with the beat.
class CircularPainter extends VisualizerPainter {
  CircularPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final n = data.values.length;
    final baseR = math.min(size.width, size.height) * 0.16;
    final maxLen = math.min(size.width, size.height) * 0.30 * config.intensity;
    final rot = data.phase;

    // Inner ring.
    canvas.drawCircle(
      center,
      baseR * 0.86,
      Paint()
        ..color = colorAt(0.5).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Beat-pulsing core.
    canvas.drawCircle(
      center,
      baseR * (0.45 + data.bass * 0.25),
      glowingPaint(colorAt(0.1, ).withOpacity(0.9)),
    );

    final strokeWidth = (math.pi * baseR / n) * 0.55;
    for (var i = 0; i < n; i++) {
      final angle = 2 * math.pi * i / n - math.pi / 2 + rot;
      final v = data.values[i];
      final len = 2 + v * maxLen;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final p0 = center + dir * baseR;
      final p1 = center + dir * (baseR + len);
      final color = colorAt(i / (n - 1));

      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      if (config.glow) {
        canvas.drawLine(
          p0,
          p1,
          Paint()
            ..color = color.withOpacity(0.5)
            ..strokeWidth = strokeWidth * 1.8
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius),
        );
      }
      canvas.drawLine(p0, p1, paint);
    }
  }
}
