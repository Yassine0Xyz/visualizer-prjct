import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class NeonBarsPainter extends VisualizerPainter {
  NeonBarsPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    final count = data.values.length;
    if (count == 0) return;

    final slot = size.width / count;
    final barWidth = slot * 0.62;
    final maxHeight = size.height * 0.70 * config.intensity;
    final baseline = size.height * 0.92;

    for (var i = 0; i < count; i++) {
      final value = data.values[i].clamp(0.0, 1.0).toDouble();
      final height = math.max(2.0, maxHeight * value).toDouble();
      final x = i * slot + (slot - barWidth) / 2;
      final y = baseline - height;
      final color = colorAt(i / math.max(1, count - 1), energy: data.energy, bass: data.bass);
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, height),
        Radius.circular(barWidth / 2),
      );

      if (config.glow) {
        canvas.drawRRect(
          bar,
          Paint()
            ..color = color.withValues(alpha: 0.36 + value * 0.30)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius),
        );
      }
      canvas.drawRRect(bar, Paint()..color = color);

      final tipHeight = math.min(4.0, height).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, tipHeight),
          Radius.circular(barWidth / 2),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.45 + value * 0.35),
      );
    }
  }
}
