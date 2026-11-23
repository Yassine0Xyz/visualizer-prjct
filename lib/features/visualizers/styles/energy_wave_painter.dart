import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class EnergyWavePainter extends VisualizerPainter {
  EnergyWavePainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    final count = data.values.length;
    if (count < 2) return;

    final centerY = size.height * 0.5;
    final amplitude = size.height * 0.30 * config.intensity;
    const layerCount = 4;

    for (var layer = 0; layer < layerCount; layer++) {
      final layerT = layer / (layerCount - 1);
      final points = <Offset>[];
      for (var i = 0; i < count; i++) {
        final x = i / (count - 1) * size.width;
        final value = data.values[i].clamp(0.0, 1.0).toDouble();
        final phase = data.phase * (0.45 + layerT * 0.2) + layer * 1.4;
        final ripple = math.sin(i / (count - 1) * math.pi * 4 + phase) * data.energy * 0.12;
        final displacement = (value * 0.75 + ripple) * amplitude;
        final y = centerY + (layerT - 0.5) * size.height * 0.26 - displacement;
        points.add(Offset(x, y));
      }

      final color = colorAt(layerT, energy: data.energy, bass: data.bass);
      final path = smoothPath(points);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.45 + data.energy * 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + (1 - layerT) * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (config.glow) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.65);
      }
      canvas.drawPath(path, paint);
    }
  }
}
