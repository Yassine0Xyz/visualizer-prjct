import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';

/// A compact deep-space nebula with an audio-reactive stellar rift.
class NebulaRiftPainter extends VisualizerPainter {
  NebulaRiftPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);
    final minDim = math.min(size.width, size.height);
    final center = Offset(size.width * 0.5, size.height * 0.47);
    final energy = _unit(data.energy);
    final bass = _unit(data.bass);
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final coreRadius = minDim * (0.105 + bass * 0.025);

    // Layered nebula clouds use only a handful of radial gradients.
    for (var cloud = 0; cloud < 3; cloud++) {
      final angle = phase * (cloud.isEven ? 0.018 : -0.014) + cloud * math.pi * 2 / 3;
      final orbit = minDim * (0.17 + cloud * 0.025 + mid * 0.012);
      final cloudCenter = center + Offset(math.cos(angle) * orbit, math.sin(angle) * orbit * 0.58);
      final radius = minDim * (0.22 + energy * 0.055);
      final color = colorAt(0.12 + cloud * 0.34 + high * 0.12, energy: energy, bass: bass);
      canvas.drawCircle(
        cloudCenter,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: 0.17 + energy * 0.12),
            color.withValues(alpha: 0.07 + mid * 0.04),
            Colors.transparent,
          ], stops: const [0.0, 0.38, 1.0]).createShader(
            Rect.fromCircle(center: cloudCenter, radius: radius),
          )
          ..blendMode = BlendMode.screen,
      );
    }

    // A tilted accretion ring and its broken luminous arcs frame the rift.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.22 + math.sin(phase * 0.035) * 0.025);
    final ringRect = Rect.fromCenter(
      center: Offset.zero,
      width: coreRadius * (5.8 + bass * 0.8),
      height: coreRadius * (2.0 + bass * 0.26),
    );
    for (var layer = 0; layer < 2; layer++) {
      final color = colorAt(0.34 + layer * 0.36 + high * 0.10, energy: energy, bass: bass);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer == 0 ? 1.0 + energy * 0.6 : 2.1
        ..color = color.withValues(alpha: layer == 0 ? 0.30 + energy * 0.18 : 0.11 + bass * 0.10);
      if (config.glow && layer == 1) {
        ringPaint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          (config.glowRadius * 0.22).clamp(0.8, 4.0).toDouble(),
        );
      }
      canvas.drawArc(ringRect, phase * (layer == 0 ? 0.12 : -0.08) + layer * 1.2,
          math.pi * (1.15 + high * 0.25), false, ringPaint);
      canvas.drawArc(ringRect, phase * -0.07 + math.pi + layer * 0.8,
          math.pi * (0.25 + bass * 0.18), false, ringPaint);
    }
    canvas.restore();

    // The dark core has a colored event horizon, so the center reads as a rift.
    final horizonRadius = coreRadius * (0.72 + bass * 0.12);
    final horizonRect = Rect.fromCircle(center: center, radius: horizonRadius * 2.5);
    canvas.drawCircle(
      center,
      horizonRadius * 2.5,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.transparent,
          colorAt(0.68, energy: energy, bass: bass).withValues(alpha: 0.12 + energy * 0.10),
          Colors.transparent,
        ], stops: const [0.48, 0.70, 1.0]).createShader(horizonRect)
        ..blendMode = BlendMode.screen,
    );
    canvas.drawCircle(center, horizonRadius, Paint()..color = const Color(0xFF050611));
    canvas.drawCircle(
      center,
      horizonRadius * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + high * 0.6
        ..color = Colors.white.withValues(alpha: 0.30 + high * 0.22),
    );

    // Deterministic starfield twinkles from the visualizer phase; no timers or allocations persist.
    const starCount = 52;
    for (var i = 0; i < starCount; i++) {
      final seed = i + 1;
      final xUnit = ((seed * 73) % 101) / 100.0;
      final yUnit = ((seed * 47 + 19) % 103) / 102.0;
      final twinkle = 0.42 + 0.58 * math.sin(phase * (0.18 + (i % 5) * 0.025) + i * 1.71).abs();
      final radius = minDim * (0.0010 + (i % 4) * 0.00045 + high * 0.00035);
      final position = Offset(xUnit * size.width, yUnit * size.height);
      final starColor = i % 5 == 0 ? colorAt(0.78, energy: energy, bass: bass) : Colors.white;
      canvas.drawCircle(
        position,
        radius,
        Paint()..color = starColor.withValues(alpha: (0.20 + twinkle * 0.48 + high * 0.12).clamp(0.0, 0.85).toDouble()),
      );
    }

    // A short spectral jet is driven by the strongest low and high energy.
    final jetLength = minDim * (0.15 + bass * 0.10 + energy * 0.05);
    for (var side = -1; side <= 1; side += 2) {
      final start = center + Offset(0, side * horizonRadius * 0.72);
      final end = start + Offset(0, side * jetLength);
      final color = colorAt(side < 0 ? 0.82 : 0.18, energy: energy, bass: bass);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          start.dx + math.sin(phase * 0.06 + side) * minDim * 0.018,
          (start.dy + end.dy) * 0.52,
          end.dx,
          end.dy,
        );
      final jetPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + high * 1.4
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.12 + energy * 0.10 + high * 0.08);
      if (config.glow) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 + high * 2
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.10 + energy * 0.08)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, (config.glowRadius * 0.24).clamp(0.8, 4.5).toDouble());
        canvas.drawPath(path, glowPaint);
      }
      canvas.drawPath(path, jetPaint);
    }
  }

  double _unit(double value) => value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
