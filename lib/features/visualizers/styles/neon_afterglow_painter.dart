import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';
import 'neon_bars_painter.dart';

/// A refined Neon Bars variation with restrained glassy scanlines and spectral caps.
class NeonAfterglowPainter extends VisualizerPainter {
  NeonAfterglowPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    NeonBarsPainter(data, config, theme).paint(canvas, size);
    final count = data.values.length;
    if (count == 0 || size.isEmpty) return;
    final slot = size.width / count;
    final baseline = size.height * 0.92;
    final maxHeight = size.height * 0.70 * config.intensity;
    final minDimension = math.min(size.width, size.height);
    for (var i = 0; i < count; i++) {
      final value = data.values[i].clamp(0.0, 1.0).toDouble();
      if (value < 0.045) continue;
      final color = colorAt(i / math.max(1, count - 1), energy: data.energy, bass: data.bass);
      final x = (i + 0.5) * slot;
      final y = baseline - math.max(2.0, maxHeight * value).toDouble();
      final glintRadius = math.min(minDimension * (0.004 + value * 0.004), slot * 0.18).toDouble();
      if (config.glow && value > 0.10) {
        final bloomRadius = math.min(minDimension * (0.018 + value * 0.028), slot * 0.68)
            .toDouble();
        final bloomRect = Rect.fromCircle(center: Offset(x, y), radius: bloomRadius);
        canvas.drawCircle(
          Offset(x, y),
          bloomRadius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: 0.25 + value * 0.18),
                color.withValues(alpha: 0.09 + value * 0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.36, 1.0],
            ).createShader(bloomRect)
            ..blendMode = BlendMode.screen,
        );
        canvas.drawCircle(
          Offset(x, y),
          bloomRadius * 0.55,
          Paint()
            ..color = color.withValues(alpha: 0.18 + value * 0.12)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              (config.glowRadius * 0.28).clamp(0.8, 4.5).toDouble(),
            ),
        );
      }
      canvas.drawCircle(
        Offset(x, y),
        glintRadius,
        Paint()..color = Colors.white.withValues(alpha: 0.28 + value * 0.36),
      );
      if (value > 0.72) {
        final flareLength = glintRadius * (2.5 + value);
        final flarePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.18 + value * 0.16)
          ..strokeWidth = 0.65
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x - flareLength, y), Offset(x + flareLength, y), flarePaint);
        canvas.drawLine(Offset(x, y - flareLength * 0.72), Offset(x, y + flareLength * 0.72), flarePaint);
      }
      if (i % 3 == 0 && value > 0.32) {
        final streakHeight = minDimension * (0.018 + value * 0.025);
        canvas.drawLine(
          Offset(x, y - streakHeight),
          Offset(x, y - glintRadius * 1.5),
          Paint()
            ..color = color.withValues(alpha: 0.22 + value * 0.18)
            ..strokeWidth = math.max(0.6, slot * 0.035).toDouble()
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }
}
