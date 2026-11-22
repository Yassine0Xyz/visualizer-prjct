import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// Equalizer wall: a grid of rounded blocks, each column driven by one band.
class ColumnsPainter extends VisualizerPainter {
  ColumnsPainter(super.data, super.config, super.theme);

  static const int _rows = 14;

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    const cols = 24;
    final n = data.values.length;
    final padX = size.width * 0.06;
    final padY = size.height * 0.14;
    final gridW = size.width - padX * 2;
    final gridH = size.height - padY * 2;
    final cellW = gridW / cols;
    final cellH = gridH / _rows;
    final blockW = cellW * 0.62;
    final blockH = cellH * 0.58;

    final dimPaint = Paint()..color = Colors.white.withOpacity(0.05);

    for (var c = 0; c < cols; c++) {
      // Sample the 48-band spectrum into 24 columns.
      final band = (c * (n - 1) / (cols - 1)).round();
      final v = data.values[band];
      final lit = (v * _rows).ceil();

      for (var r = 0; r < _rows; r++) {
        final fromBottom = _rows - 1 - r;
        final x = padX + c * cellW + (cellW - blockW) / 2;
        final y = padY + r * cellH + (cellH - blockH) / 2;

        if (fromBottom < lit) {
          final t = fromBottom / _rows;
          final color = colorAt(c / (cols - 1) * 0.7 + t * 0.3);
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, blockW, blockH),
            Radius.circular(blockH * 0.4),
          );
          if (config.glow && fromBottom >= lit - 2) {
            canvas.drawRRect(
              rect,
              Paint()
                ..color = color.withOpacity(0.5)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.6),
            );
          }
          canvas.drawRRect(
            rect,
            Paint()
              ..color = color.withOpacity(0.45 + 0.55 * (fromBottom + 1) / _rows),
          );
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, blockW, blockH),
              Radius.circular(blockH * 0.4),
            ),
            dimPaint,
          );
        }
      }
    }
  }
}
