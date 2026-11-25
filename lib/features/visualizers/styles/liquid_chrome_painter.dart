import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class LiquidChromePainter extends VisualizerPainter {
  LiquidChromePainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);

    final values = data.values;
    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height);
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final energy = _unit(data.energy);
    final bass = _unit(data.bass);
    final intensity = config.intensity.isFinite ? config.intensity.clamp(0.3, 2.5).toDouble() : 1.0;
    final pulse = 1 + bass * config.bassBoost.clamp(0.5, 3.0).toDouble() * 0.035;
    final baseRadius = minDim * (0.285 + energy * 0.025) * pulse;

    // A small fixed contour keeps the organic silhouette smooth and inexpensive.
    const segments = 48;
    final points = <Offset>[];
    for (var i = 0; i < segments; i++) {
      final angle = 2 * math.pi * i / segments;
      final band = values.isEmpty
          ? 0.0
          : _unit(values[(i * values.length ~/ segments).clamp(0, values.length - 1)]);
      final lobe = math.sin(angle * 3 + phase * 0.72) * 0.035 +
          math.cos(angle * 2 - phase * 0.43) * 0.022;
      final spectral = (band - 0.25) * 0.12 * intensity;
      final radius = baseRadius * (1 + lobe + spectral);
      points.add(center + Offset(math.cos(angle) * radius * 1.08, math.sin(angle) * radius * 0.82));
    }
    final blob = smoothPath(points)..close();

    final c0 = colorAt(0.12, energy: energy, bass: bass);
    final c1 = colorAt(0.48, energy: energy, bass: bass);
    final c2 = colorAt(0.86, energy: energy, bass: bass);
    final bounds = Rect.fromCenter(center: center, width: baseRadius * 2.3, height: baseRadius * 1.85);

    canvas.drawPath(
      blob,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.34, -0.48),
          radius: 1.1,
          colors: [
            const Color(0xFFF7FBFF).withValues(alpha: 0.92),
            c0.withValues(alpha: 0.94),
            const Color(0xFF18212B),
            c2.withValues(alpha: 0.92),
            const Color(0xFFE9F2FA).withValues(alpha: 0.76),
          ],
          stops: const [0, 0.18, 0.46, 0.76, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      blob,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, minDim * 0.003)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            c1.withValues(alpha: 0.46),
            const Color(0xFF070B10).withValues(alpha: 0.86),
            Colors.white.withValues(alpha: 0.72),
          ],
        ).createShader(bounds),
    );

    // Restrained curved bands and pinpoint sheen, clipped to the liquid body.
    canvas.save();
    canvas.clipPath(blob);
    final bandY = center.dy - baseRadius * (0.25 + 0.04 * math.sin(phase));
    final band = Path()
      ..moveTo(center.dx - baseRadius * 1.2, bandY)
      ..cubicTo(center.dx - baseRadius * 0.48, bandY - baseRadius * 0.18, center.dx + baseRadius * 0.38,
          bandY - baseRadius * 0.08, center.dx + baseRadius * 1.2, bandY - baseRadius * 0.22);
    canvas.drawPath(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2.0, minDim * 0.022)
        ..shader = LinearGradient(colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.68),
          c0.withValues(alpha: 0.34),
          Colors.white.withValues(alpha: 0.0),
        ]).createShader(bounds),
    );
    final lowerBand = Path()
      ..moveTo(center.dx - baseRadius * 1.1, center.dy + baseRadius * 0.32)
      ..quadraticBezierTo(center.dx, center.dy + baseRadius * 0.10, center.dx + baseRadius * 1.1, center.dy + baseRadius * 0.28);
    canvas.drawPath(
      lowerBand,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, minDim * 0.008)
        ..color = c2.withValues(alpha: 0.42),
    );
    canvas.drawCircle(
      center + Offset(-baseRadius * 0.31, -baseRadius * 0.36),
      math.max(1.2, minDim * 0.008),
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
    canvas.restore();
  }

  double _unit(double value) => value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
