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
    final minDimension = math.min(size.width, size.height);
    final trailWidth = math.max(1.0, math.min(barWidth * 0.42, minDimension * 0.008)).toDouble();

    for (var i = 0; i < count; i++) {
      final value = data.values[i].clamp(0.0, 1.0).toDouble();
      final previous = data.previousValues[i].clamp(0.0, 1.0).toDouble();
      final height = math.max(2.0, maxHeight * value).toDouble();
      final x = i * slot + (slot - barWidth) / 2;
      final y = baseline - height;
      final color = colorAt(i / math.max(1, count - 1), energy: data.energy, bass: data.bass);
      final previousHeight = math.max(2.0, maxHeight * previous).toDouble();
      final trailY = baseline - previousHeight;
      if ((height - previousHeight).abs() > 1.5) {
        final trailRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + (barWidth - trailWidth) / 2,
            math.min(y, trailY).toDouble(),
            trailWidth,
            (height - previousHeight).abs(),
          ),
          Radius.circular(trailWidth / 2),
        );
        canvas.drawRRect(
          trailRect,
          Paint()..color = color.withValues(alpha: 0.20 + value * 0.12),
        );
      }
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
      if (config.glow && value > 0.08) {
        canvas.drawCircle(
          Offset(x + barWidth / 2, y + tipHeight / 2),
          math.min(minDimension * 0.012, barWidth * 0.75).toDouble(),
          Paint()
            ..color = color.withValues(alpha: 0.34 + value * 0.30)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.42),
        );
      }
    }
  }
}
