import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';
/// A scrolling, time-oriented spectrogram rendered from recent spectrum frames.
class WaterfallPainter extends VisualizerPainter {
  WaterfallPainter(super.data, super.config, super.theme);
  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    const left = 14.0, right = 14.0, top = 24.0, bottom = 24.0;
    final w = math.max(1.0, size.width - left - right);
    final h = math.max(1.0, size.height - top - bottom);
    final frames = data.history;
    if (frames.isEmpty) return;
    final cellW = w / data.values.length;
    final cellH = h / frames.length;
    final paint = Paint();
    for (var row = 0; row < frames.length; row++) {
      final frame = frames[row];
      final age = row / math.max(1, frames.length - 1);
      for (var band = 0; band < frame.length; band++) {
        final v = frame[band].clamp(0.0, 1.0).toDouble();
        final c = colorAt(band / (frame.length - 1), energy: v, bass: data.bass);
        paint.color = c.withValues(alpha: (0.05 + v * 0.88) * (0.35 + age * 0.65));
        final rect = Rect.fromLTWH(left + band * cellW, top + (frames.length - row - 1) * cellH, math.max(0.7, cellW - 0.6), math.max(0.7, cellH - 0.5));
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.2)), paint);
      }
    }
    final border = Paint()..color = Colors.white.withValues(alpha: 0.12)..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), const Radius.circular(8)), border);
  }
}
