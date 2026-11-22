import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// Symmetric bars expanding above and below a luminous horizontal axis.
class MirrorPainter extends VisualizerPainter {
  MirrorPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final n = data.values.length;
    final centerY = size.height / 2;
    final slot = size.width / n;
    final barWidth = slot * 0.6;
    final maxH = size.height * 0.34 * config.intensity;

    // Center axis glow.
    if (config.glow) {
      canvas.drawRect(
        Rect.fromLTWH(0, centerY - 1, size.width, 2),
        Paint()
          ..color = colorAt(0.5).withOpacity(0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius),
      );
    }

    for (var i = 0; i < n; i++) {
      final v = data.values[i];
      final h = (v * maxH).clamp(1.0, maxH);
      final x = i * slot + (slot - barWidth) / 2;
      final color = colorAt(i / (n - 1));

      final top = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, centerY - h - 2, barWidth, h),
        Radius.vertical(top: Radius.circular(barWidth / 2)),
      );
      final bottom = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, centerY + 2, barWidth, h * 0.92),
        Radius.vertical(bottom: Radius.circular(barWidth / 2)),
      );

      if (config.glow) {
        final blur = Paint()
          ..color = color.withOpacity(0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius);
        canvas.drawRRect(top, blur);
        canvas.drawRRect(bottom, blur);
      }
      canvas.drawRRect(top, Paint()..color = color);
      canvas.drawRRect(bottom, Paint()..color = color.withOpacity(0.75));
    }
  }
}
