import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// A filled polar spectrum blob with an echoing inner contour.
class RadialPainter extends VisualizerPainter {
  RadialPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final n = data.values.length;
    final baseR = math.min(size.width, size.height) * 0.14;
    final maxR = math.min(size.width, size.height) * 0.34 * config.intensity;
    final rot = data.phase * 0.6;

    Offset polar(int i, double radius) {
      final angle = 2 * math.pi * i / n - math.pi / 2 + rot;
      return center + Offset(math.cos(angle), math.sin(angle)) * radius;
    }

    final outer = <Offset>[
      for (var i = 0; i <= n; i++) polar(i % n, baseR + data.values[i % n] * maxR),
    ];
    final inner = <Offset>[
      for (var i = 0; i <= n; i++)
        polar(i % n, (baseR + data.values[i % n] * maxR) * 0.62),
    ];

    // Filled blob.
    final path = Path()..addPolygon(outer, true);
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colorAt(0.1).withOpacity(0.55),
            colorAt(0.7).withOpacity(0.15),
          ],
        ).createShader(Offset.zero & size),
    );

    // Outer stroke.
    canvas.drawPath(
      path,
      glowingPaint(colorAt(0.3), strokeWidth: 2.5, fill: false),
    );

    // Inner echo contour.
    canvas.drawPath(
      Path()..addPolygon(inner, true),
      Paint()
        ..color = colorAt(0.8).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Center dot.
    canvas.drawCircle(center, 3 + data.energy * 5, glowingPaint(colorAt(0.5)));
  }
}
