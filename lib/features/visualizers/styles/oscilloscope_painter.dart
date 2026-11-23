import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';
/// Displays actual left/right PCM waveform snapshots from the decoded audio.
class OscilloscopePainter extends VisualizerPainter {
  OscilloscopePainter(super.data, super.config, super.theme);
  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    final left = data.waveformLeft;
    final right = data.waveformRight;
    if (left.isEmpty || right.isEmpty) return;
    final midY = size.height * 0.5;
    final amplitude = size.height * 0.31 * config.intensity;
    final count = math.min(left.length, right.length);
    // Quiet center guide line.
    canvas.drawLine(Offset(size.width * 0.06, midY), Offset(size.width * 0.94, midY),
      Paint()..color = Colors.white.withValues(alpha: 0.12)..strokeWidth = 1);
    for (var channel = 0; channel < 2; channel++) {
      final source = channel == 0 ? left : right;
      final centerY = channel == 0 ? size.height * 0.31 : size.height * 0.69;
      final points = <Offset>[];
      for (var i = 0; i < count; i++) {
        final x = size.width * (0.04 + 0.92 * i / (count - 1));
        final y = centerY - source[i].clamp(-1.0, 1.0) * amplitude * 0.55;
        points.add(Offset(x, y));
      }
      final path = smoothPath(points);
      final c = colorAt(channel == 0 ? 0.22 : 0.76, energy: data.energy, bass: data.bass);
      if (config.glow) {
        canvas.drawPath(path, Paint()..color = c.withValues(alpha: 0.48)..style = PaintingStyle.stroke
          ..strokeWidth = 6..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.7));
      }
      canvas.drawPath(path, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
      final label = channel == 0 ? 'L' : 'R';
      final tp = TextPainter(text: TextSpan(text: label, style: TextStyle(color: c.withValues(alpha: 0.55), fontSize: 10, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(12, centerY - 6));
    }
  }
}
