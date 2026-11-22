import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../visualizer_config.dart';
import '../visualizer_data.dart';
import '../visualizer_theme.dart';

/// Base class for all visualizer painters.
///
/// Painters are intentionally decoupled from playback: they receive a
/// [VisualizerData] snapshot, a [VisualizerConfig] and a
/// [VisualizerThemeData] and render purely from those. Extract them into
/// another app by copying this folder and feeding [VisualizerData].
abstract class VisualizerPainter extends CustomPainter {
  VisualizerPainter(this.data, this.config, this.theme);

  final VisualizerData data;
  final VisualizerConfig config;
  final VisualizerThemeData theme;

  /// Theme color sampled at t in 0..1, brightened by [data.energy].
  Color colorAt(double t) => theme.colorAt(t, energy: data.energy);

  /// Deep space background with a faint theme-colored aura.
  void paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.6),
        radius: 1.4,
        colors: [theme.deepBackground, const Color(0xFF000000)],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    final aura = Paint()
      ..shader = RadialGradient(
        colors: [
          theme.colorAt(0.5, energy: data.energy).withOpacity(0.10 + data.energy * 0.12),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, aura);
  }

  /// Paint with an optional glow blur.
  Paint glowingPaint(Color color, {double strokeWidth = 0, bool fill = true}) {
    final paint = Paint()
      ..color = color
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (config.glow) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.6);
    }
    return paint;
  }

  /// Catmull-Rom-smoothed path through [points], closed if requested.
  Path smoothPath(List<Offset> points, {bool close = false, Size? closeTo}) {
    final path = Path();
    if (points.length < 2) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[math.max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[math.min(points.length - 1, i + 2)];
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
