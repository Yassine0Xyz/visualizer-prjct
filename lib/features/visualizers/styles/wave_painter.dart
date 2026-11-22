import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// Smooth interpolated spectrum line with a soft fill beneath it.
class WavePainter extends VisualizerPainter {
  WavePainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final n = data.values.length;
    final centerY = size.height * 0.55;
    final amp = size.height * 0.34 * config.intensity;

    final points = <Offset>[
      for (var i = 0; i < n; i++)
        Offset(
          i / (n - 1) * size.width,
          centerY - data.values[i] * amp,
        ),
    ];

    // Faint mirrored echo below the center line.
    final echo = <Offset>[
      for (var i = 0; i < n; i++)
        Offset(
          i / (n - 1) * size.width,
          centerY + data.values[i] * amp * 0.55,
        ),
    ];

    final echoPath = smoothPath(echo);
    canvas.drawPath(
      echoPath,
      Paint()
        ..color = colorAt(0.5).withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = config.glow ? MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.5) : null,
    );

    // Gradient fill under the main wave.
    final fillPath = smoothPath(points, close: true, closeTo: size);
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorAt(0.35).withOpacity(0.35),
            colorAt(0.8).withOpacity(0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    // Main glowing stroke.
    canvas.drawPath(
      smoothPath(points),
      glowingPaint(colorAt(0.2), strokeWidth: 3.5, fill: false),
    );
  }
}
