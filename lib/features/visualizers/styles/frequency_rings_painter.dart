import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class FrequencyRingsPainter extends VisualizerPainter {
  FrequencyRingsPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    final center = size.center(Offset.zero);
    final minDimension = math.min(size.width, size.height);
    final count = data.values.length;
    if (count == 0) return;

    const ringCount = 8;
    const segmentCount = 12;
    for (var ring = 0; ring < ringCount; ring++) {
      final ringT = ring / (ringCount - 1);
      final radius = minDimension * (0.12 + ringT * 0.31);
      final segmentLength = 2 * math.pi / segmentCount;
      for (var segment = 0; segment < segmentCount; segment++) {
        final rangeStart = ring < 3 ? 0 : (ring < 6 ? count ~/ 3 : (count * 2) ~/ 3);
        final rangeEnd = ring < 3 ? count ~/ 3 : (ring < 6 ? (count * 2) ~/ 3 : count);
        final bandIndex =
            (rangeStart + (segment * 2 + ring) % math.max(1, rangeEnd - rangeStart)) % count;
        final safeBandIndex = bandIndex.toInt();
        final value = data.values[safeBandIndex].clamp(0.0, 1.0).toDouble();
        final sweep = segmentLength * (0.30 + value * 0.62);
        final rotation = data.phase * (ring.isEven ? 0.35 : -0.28);
        final startAngle = segment * segmentLength + rotation;
        final color = colorAt(safeBandIndex / count, energy: data.energy, bass: data.bass);
        final paint = Paint()
          ..color = color.withValues(alpha: 0.38 + value * 0.58)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.5 + value * 2.2;
        if (config.glow && value > 0.35) {
          paint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.55);
        }
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius + value * minDimension * 0.012),
          startAngle,
          sweep,
          false,
          paint,
        );
      }
    }
  }
}
