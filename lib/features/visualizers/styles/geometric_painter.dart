import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// Rotating low-poly rings that breathe with bass, mids and highs.
class GeometricPainter extends VisualizerPainter {
  GeometricPainter(super.data, super.config, super.theme);

  static const int _rings = 3;

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height);
    final drivers = [data.bass, data.mid, data.high];

    for (var ring = 0; ring < _rings; ring++) {
      final t = ring / (_rings - 1);
      final sides = 6 + ring * 2;
      final base = minDim * (0.14 + 0.11 * ring);
      final radius = base * (1 + drivers[ring] * 0.55 * config.intensity);
      final rot = data.phase * (ring.isEven ? 0.9 : -0.7) + ring * 0.4;
      final color = colorAt(t);

      final vertices = <Offset>[
        for (var i = 0; i < sides; i++)
          center +
              Offset(
                math.cos(2 * math.pi * i / sides + rot),
                math.sin(2 * math.pi * i / sides + rot),
              ) *
                  radius,
      ];

      final path = Path()..addPolygon(vertices, true);
      if (config.glow) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Vertex nodes on the outer ring.
      if (ring == _rings - 1) {
        for (final v in vertices) {
          canvas.drawCircle(v, 2.5 + drivers[ring] * 3, glowingPaint(color));
        }
      }
    }

    // Center cross pulse.
    final cross = data.energy * minDim * 0.05;
    canvas.drawCircle(center, 3 + cross, glowingPaint(colorAt(0.5)));
  }
}
