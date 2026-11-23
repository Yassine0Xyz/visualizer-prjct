import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// Classic spectrum bars anchored to the bottom edge.
class BarsPainter extends VisualizerPainter {
  BarsPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final n = data.values.length;
    final slot = size.width / n;
    final barWidth = slot * 0.48;
    final maxH = size.height * 0.62;

    for (var i = 0; i < n; i++) {
      final v = data.values[i];
      final h = (v * maxH * config.intensity).clamp(2.0, maxH).toDouble();
      final x = i * slot + (slot - barWidth) / 2;
      final color = colorAt(i / (n - 1));

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barWidth, h),
        Radius.circular(3),
      );
      if (config.glow) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = color.withValues(alpha: 0.55)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius),
        );
      }
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color, theme.colorAt(i / (n - 1), energy: 1)],
          ).createShader(rect.outerRect),
      );
    }

    // Subtle baseline.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 1.5, size.width, 1.5),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }
}
