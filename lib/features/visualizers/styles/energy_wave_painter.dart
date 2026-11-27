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
    final bandRanges = <(int, int)>[
      (0, math.max(1, count ~/ 4).toInt()),
      (count ~/ 4, math.max(count ~/ 4 + 1, count ~/ 2).toInt()),
      (count ~/ 2, math.max(count ~/ 2 + 1, (count * 3) ~/ 4).toInt()),
      ((count * 3) ~/ 4, count),
    ];
    final laneSpacing = math.min(size.height * 0.12, math.min(size.width, size.height) * 0.14)
        .toDouble();

    // Soft lane guides make the four frequency layers easier to read at a glance.
    for (var lane = 0; lane < layerCount; lane++) {
      final y = centerY + (lane - (layerCount - 1) / 2) * laneSpacing;
      canvas.drawLine(
        Offset(size.width * 0.06, y),
        Offset(size.width * 0.94, y),
        Paint()
          ..color = colorAt(lane / (layerCount - 1)).withValues(alpha: 0.07)
          ..strokeWidth = 1,
      );
    }

    for (var layer = 0; layer < layerCount; layer++) {
      final layerT = layer / (layerCount - 1);
      final range = bandRanges[layer];
      final rangeStart = range.$1.clamp(0, count - 1).toInt();
      final rangeEnd = range.$2.clamp(rangeStart + 1, count).toInt();
      final points = <Offset>[];
      for (var i = 0; i < count; i++) {
        final x = i / (count - 1) * size.width;
        final bandPosition = i / (count - 1);
        final bandIndex = (rangeStart + (bandPosition * (rangeEnd - rangeStart - 1)).round())
            .clamp(0, count - 1)
            .toInt();
        final value = data.values[bandIndex].clamp(0.0, 1.0).toDouble();
        final phase = data.phase * (0.45 + layerT * 0.2) + layer * 1.4;
        final ripple = math.sin(bandPosition * math.pi * 4 + phase) * data.energy * 0.08;
        final displacement = (value * (0.52 + layerT * 0.20) + ripple) * amplitude;
        final y = centerY + (layer - (layerCount - 1) / 2) * laneSpacing - displacement;
        points.add(Offset(x, y));
      }

      final color = colorAt(layerT, energy: data.energy, bass: data.bass);
      final path = smoothPath(points);
      if (layer == 0) {
        final underglow = Paint()
          ..color = color.withValues(alpha: 0.10 + data.bass * 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7 + data.bass * 5
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.8);
        if (config.glow) canvas.drawPath(path, underglow);
      }
      final paint = Paint()
        ..color = color.withValues(alpha: 0.48 + data.energy * 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + (1 - layerT) * 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (config.glow) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.65);
      }
      canvas.drawPath(path, paint);
    }
  }
}
