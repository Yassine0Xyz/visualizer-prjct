import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class LiquidChromePainter extends VisualizerPainter {
  LiquidChromePainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
    paintBackground(canvas, size);

    final values = data.values;
    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height);
    if (minDim <= 0) return;

    final phase = data.phase.isFinite ? data.phase : 0.0;
    final beat = data.beatPhase.isFinite ? data.beatPhase : phase;
    final energy = _unit(data.energy);
    final bass = _unit(data.bass);
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final intensity = _finiteClamp(config.intensity, 1.1, 0.3, 2.5);
    final bassBoost = _finiteClamp(config.bassBoost, 1.0, 0.5, 3.0);
    final bassDrive = (bass * bassBoost).clamp(0.0, 2.0).toDouble();
    final pulse = 1.0 + bassDrive * 0.045 + energy * 0.018;
    final baseRadius = minDim * (0.292 + energy * 0.018) * pulse;

    // Sample the smoothed spectrum around the contour to make its silhouette react locally.
    const segments = 48;
    final points = <Offset>[];
    for (var i = 0; i < segments; i++) {
      final angle = 2 * math.pi * i / segments;
      final band = values.isEmpty
          ? 0.0
          : _unit(values[
              (i * values.length ~/ segments).clamp(0, values.length - 1)]);
      final localBand =
          values.isEmpty ? (bass * 0.42 + mid * 0.38 + high * 0.20) : band;
      final harmonics =
          math.sin(angle * 3 + phase * 0.72) * (0.026 + bassDrive * 0.006) +
              math.cos(angle * 2 - phase * 0.43) * (0.018 + mid * 0.008) +
              math.sin(angle * 5 + phase * 0.31) * (0.008 + high * 0.008);
      final spectral = (localBand - 0.24) * 0.115 * intensity;
      final radius = baseRadius * (1 + harmonics + spectral);
      points.add(center +
          Offset(math.cos(angle) * radius * 1.08,
              math.sin(angle) * radius * 0.82));
    }
    final blob = smoothPath(points)..close();
    final c0 = colorAt(0.12 + bass * 0.08, energy: energy, bass: bass);
    final c1 = colorAt(0.48 + mid * 0.10, energy: energy, bass: bass);
    final c2 = colorAt(0.84 + high * 0.08, energy: energy, bass: bass);
    final bounds = Rect.fromCenter(
      center: center,
      width: math.min(size.width, baseRadius * 2.42),
      height: math.min(size.height, baseRadius * 1.92),
    );

    canvas.drawPath(
      blob,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.34, -0.48),
          radius: 1.12,
          colors: [
            const Color(0xFFFFFFFF).withValues(alpha: 0.98),
            const Color(0xFFBFD5E8).withValues(alpha: 0.97),
            c0.withValues(alpha: 0.98),
            const Color(0xFF17232E),
            c2.withValues(alpha: 0.96),
            const Color(0xFFE7F1FA).withValues(alpha: 0.88),
          ],
          stops: const [0, 0.10, 0.25, 0.49, 0.77, 1],
        ).createShader(bounds),
    );

    // A fine rim and a restrained offset shadow give the chrome body depth without masking it.
    canvas.drawPath(
      blob,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, minDim * 0.0028)
        ..color = const Color(0xFF050A10).withValues(alpha: 0.78),
    );
    canvas.drawPath(
      blob,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.75, minDim * 0.002)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.90),
            c1.withValues(alpha: 0.42),
            const Color(0xFF080E15).withValues(alpha: 0.72),
            Colors.white.withValues(alpha: 0.58),
          ],
        ).createShader(bounds),
    );

    canvas.save();
    canvas.clipPath(blob);

    // Broad soft reflection and a thin companion streak read as curved metal, not a flat stripe.
    final bandY = center.dy - baseRadius * (0.22 + 0.035 * math.sin(phase));
    final band = Path()
      ..moveTo(center.dx - baseRadius * 1.05, bandY)
      ..cubicTo(
        center.dx - baseRadius * 0.48,
        bandY - baseRadius * (0.15 + high * 0.025),
        center.dx + baseRadius * 0.36,
        bandY - baseRadius * 0.045,
        center.dx + baseRadius * 1.05,
        bandY - baseRadius * 0.19,
      );
    canvas.drawPath(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2.0, minDim * (0.018 + high * 0.004))
        ..shader = LinearGradient(colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.48 + high * 0.18),
          c0.withValues(alpha: 0.30),
          Colors.white.withValues(alpha: 0.0),
        ]).createShader(bounds),
    );
    final glint = Path()
      ..moveTo(center.dx - baseRadius * 0.66, bandY - baseRadius * 0.035)
      ..quadraticBezierTo(
        center.dx - baseRadius * 0.14,
        bandY - baseRadius * (0.13 + high * 0.025),
        center.dx + baseRadius * 0.36,
        bandY - baseRadius * 0.10,
      );
    canvas.drawPath(
      glint,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(0.7, minDim * 0.0022)
        ..color = Colors.white.withValues(alpha: 0.72),
    );

    final lowerY = center.dy + baseRadius * (0.30 + 0.025 * math.sin(beat));
    final lowerBand = Path()
      ..moveTo(center.dx - baseRadius * 0.94, lowerY)
      ..quadraticBezierTo(
        center.dx,
        lowerY - baseRadius * (0.17 + bassDrive * 0.018),
        center.dx + baseRadius * 0.94,
        lowerY - baseRadius * 0.04,
      );
    canvas.drawPath(
      lowerBand,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, minDim * 0.006)
        ..color = c2.withValues(alpha: 0.30 + mid * 0.16),
    );

    final highlightRadius = math.max(0.9, minDim * (0.006 + high * 0.002));
    canvas.drawCircle(
      center + Offset(-baseRadius * 0.31, -baseRadius * 0.36),
      highlightRadius,
      Paint()..color = Colors.white.withValues(alpha: 0.76 + high * 0.18),
    );
    canvas.restore();
  }

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;

  double _finiteClamp(double value, double fallback, double min, double max) =>
      value.isFinite ? value.clamp(min, max).toDouble() : fallback;
}
