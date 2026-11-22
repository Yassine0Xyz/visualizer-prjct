import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// Layered liquid waves. Amplitude comes from bass/mid/high; the drift of
/// the phase is driven by the overall energy, so still audio stays still.
class FluidPainter extends VisualizerPainter {
  FluidPainter(super.data, super.config, super.theme);

  static const int _layers = 3;

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final rect = Offset.zero & size;
    final amps = [data.bass, data.mid, data.high];
    final phase = data.phase;

    for (var layer = _layers - 1; layer >= 0; layer--) {
      final t = layer / (_layers - 1);
      final baseY = size.height * (0.38 + 0.2 * layer);
      final amplitude = (10 + amps[layer] * size.height * 0.22) * config.intensity;
      final freq = 1.6 + layer * 0.9;
      final speed = phase * (0.8 + layer * 0.35);

      const steps = 48;
      final points = <Offset>[
        for (var i = 0; i <= steps; i++)
          Offset(
            i / steps * size.width,
            baseY +
                math.sin(i / steps * math.pi * freq + speed) * amplitude *
                    math.sin(math.pi * i / steps),
          ),
      ];

      // Fill down to the bottom.
      final fillPath = smoothPath(points, close: true, closeTo: size);
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorAt(0.15 + t * 0.6).withValues(alpha: 0.28),
              colorAt(0.3 + t * 0.6).withValues(alpha: 0.03),
            ],
          ).createShader(rect),
      );

      // Crest line.
      canvas.drawPath(
        smoothPath(points),
        Paint()
          ..color = colorAt(0.15 + t * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..maskFilter = config.glow
              ? MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.5)
              : null,
      );
    }
  }
}
