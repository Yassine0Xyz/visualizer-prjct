import 'package:flutter/material.dart';

import '../visualizer_config.dart';
import '../visualizer_data.dart';
import '../visualizer_theme.dart';

abstract class VisualizerPainter extends CustomPainter {
  VisualizerPainter(this.data, this.config, this.theme);

  final VisualizerData data;
  final VisualizerConfig config;
  final VisualizerThemeData theme;

  Color colorAt(double t, {double energy = 0, double bass = 0}) =>
      theme.colorAt(t, energy: energy, bass: bass);

  void paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Deep space background
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.5),
        radius: 1.6,
        colors: [theme.deepBackground, const Color(0xFF000000)],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Ambient glow
    final ambientColor = colorAt(0.5, energy: data.energy, bass: data.bass);
    final aura = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 1.2,
        colors: [
          ambientColor.withValues(alpha: 0.08 + data.energy * 0.15),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, aura);

    // Second ambient glow from bottom
    final aura2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.8),
        radius: 0.8,
        colors: [
          colorAt(0.8, energy: data.energy).withValues(alpha: 0.05 + data.bass * 0.1),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, aura2);
  }

  Paint glowingPaint(Color color, {double strokeWidth = 0, bool fill = true}) {
    final paint = Paint()
      ..color = color
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (config.glow) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.7);
    }
    return paint;
  }

  Path smoothPath(List<Offset> points, {bool close = false, Size? closeTo}) {
    final path = Path();
    if (points.length < 2) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i == 0 ? 0 : i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[i + 2 < points.length ? i + 2 : points.length - 1];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    if (close && closeTo != null) {
      path.lineTo(closeTo.width, closeTo.height);
      path.lineTo(0, closeTo.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant VisualizerPainter oldDelegate) => true;
}
