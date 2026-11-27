import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';

/// A futuristic game arena HUD with a perspective floor and a live spectrum reactor.
class HoloArenaPainter extends VisualizerPainter {
  HoloArenaPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);
    final minDim = math.min(size.width, size.height);
    if (minDim < 1) return;
    final center = Offset(size.width * 0.5, size.height * 0.46);
    final sensitivity = config.sensitivity * config.intensity;
    final energy = _unit(data.energy * sensitivity);
    final bass = _unit(data.bass * config.sensitivity * config.bassBoost);
    final high = _unit(data.high * sensitivity);
    final mid = _unit(data.mid * sensitivity);
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final accent = colorAt(0.68, energy: energy, bass: bass);
    final secondary = colorAt(0.12 + high * 0.22, energy: energy, bass: bass);

    // Perspective floor grid converges toward the reactor, with bounded line count.
    final horizonY = size.height * 0.64;
    final floorBottom = size.height * 0.98;
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = accent.withValues(alpha: 0.10 + energy * 0.08);
    for (var line = -5; line <= 5; line++) {
      final bottomX = size.width * (0.5 + line * 0.16);
      final path = Path()
        ..moveTo(size.width * 0.5 + line * minDim * 0.018, horizonY)
        ..lineTo(bottomX, floorBottom);
      canvas.drawPath(path, gridPaint);
    }
    for (var row = 0; row < 7; row++) {
      final t = row / 6;
      final eased = t * t;
      final y = horizonY + eased * (floorBottom - horizonY);
      canvas.drawLine(Offset(size.width * 0.04, y),
          Offset(size.width * 0.96, y), gridPaint);
    }

    // Holographic arena boundary: clipped-corner plate and layered scan arcs.
    final arenaWidth = math.min(size.width * 0.88, minDim * 0.88);
    final arenaHeight = math.min(size.height * 0.53, minDim * 0.76);
    final rect =
        Rect.fromCenter(center: center, width: arenaWidth, height: arenaHeight);
    final cut = minDim * 0.045;
    final plate = Path()
      ..moveTo(rect.left + cut, rect.top)
      ..lineTo(rect.right - cut, rect.top)
      ..lineTo(rect.right, rect.top + cut)
      ..lineTo(rect.right, rect.bottom - cut)
      ..lineTo(rect.right - cut, rect.bottom)
      ..lineTo(rect.left + cut, rect.bottom)
      ..lineTo(rect.left, rect.bottom - cut)
      ..lineTo(rect.left, rect.top + cut)
      ..close();
    canvas.drawPath(
      plate,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.055 + energy * 0.025),
            Colors.transparent,
            secondary.withValues(alpha: 0.035 + high * 0.025),
          ],
        ).createShader(rect),
    );
    if (config.glow) {
      canvas.drawPath(
        plate,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = accent.withValues(alpha: 0.10 + energy * 0.06)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal,
              (config.glowRadius * 0.24).clamp(0.8, 4.0).toDouble()),
      );
    }
    canvas.drawPath(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = accent.withValues(alpha: 0.38 + energy * 0.22),
    );

    // Corner brackets and moving scan bar communicate a game-interface frame.
    final bracket = minDim * 0.055;
    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square
      ..color = Colors.white.withValues(alpha: 0.46 + energy * 0.20);
    final corners = [
      (Offset(rect.left, rect.top), 1.0, 1.0),
      (Offset(rect.right, rect.top), -1.0, 1.0),
      (Offset(rect.left, rect.bottom), 1.0, -1.0),
      (Offset(rect.right, rect.bottom), -1.0, -1.0),
    ];
    for (final corner in corners) {
      final origin = corner.$1;
      final sx = corner.$2;
      final sy = corner.$3;
      canvas.drawLine(origin, origin + Offset(sx * bracket, 0), bracketPaint);
      canvas.drawLine(origin, origin + Offset(0, sy * bracket), bracketPaint);
    }
    final scanY = rect.top + ((phase * 0.035) % 1.0) * rect.height;
    canvas.drawLine(
      Offset(rect.left + cut, scanY),
      Offset(rect.right - cut, scanY),
      Paint()
        ..color = accent.withValues(alpha: 0.10 + energy * 0.08)
        ..strokeWidth = 1.0,
    );

    // Reactor rings: bass drives radius, treble drives fine radial ticks.
    final reactorRadius = minDim * (0.085 + bass * 0.035 + mid * 0.008);
    for (var ring = 0; ring < 3; ring++) {
      final radius = reactorRadius * (1.22 + ring * 0.48);
      final color = ring.isEven ? accent : secondary;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring == 1 ? 1.3 : 0.8
        ..color = color.withValues(alpha: 0.20 + energy * 0.12 + high * 0.06);
      if (config.glow && ring == 1) {
        final bloomPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = color.withValues(alpha: 0.10 + energy * 0.06)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal,
              (config.glowRadius * 0.24).clamp(0.8, 4.0).toDouble());
        canvas.drawCircle(center, radius, bloomPaint);
      }
      canvas.drawCircle(center, radius, ringPaint);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        phase * (ring.isEven ? 0.12 : -0.09) + ring * 0.9,
        math.pi * (0.52 + high * 0.20),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.52 + energy * 0.20),
      );
    }

    final bands = data.values;
    if (bands.isNotEmpty && reactorRadius > 0) {
      final tickCount = math.min(48, bands.length * 2).toInt();
      final tickPaint = Paint()..strokeCap = StrokeCap.round;
      for (var i = 0; i < tickCount; i++) {
        final bandIndex =
            (i * bands.length ~/ tickCount).clamp(0, bands.length - 1).toInt();
        final value = _unit(bands[bandIndex]);
        final angle = 2 * math.pi * i / tickCount - math.pi / 2 + phase * 0.018;
        final inner = reactorRadius * 1.84;
        final outer =
            inner + minDim * (0.012 + value * 0.05 * config.intensity);
        final a = center + Offset(math.cos(angle), math.sin(angle)) * inner;
        final b = center + Offset(math.cos(angle), math.sin(angle)) * outer;
        tickPaint
          ..color = colorAt(i / tickCount, energy: energy, bass: bass)
              .withValues(alpha: 0.28 + value * 0.62)
          ..strokeWidth = 0.65 + value * 1.45;
        canvas.drawLine(a, b, tickPaint);
      }
    }

    // Compact energy core with a narrow bloom, never a full-screen haze.
    final coreRect =
        Rect.fromCircle(center: center, radius: reactorRadius * 1.2);
    if (config.glow) {
      canvas.drawCircle(
        center,
        reactorRadius * 1.2,
        Paint()
          ..shader = RadialGradient(colors: [
            accent.withValues(alpha: 0.18 + energy * 0.12),
            secondary.withValues(alpha: 0.08 + high * 0.06),
            Colors.transparent,
          ], stops: const [
            0.0,
            0.48,
            1.0
          ]).createShader(coreRect)
          ..blendMode = BlendMode.screen,
      );
    }
    canvas.drawCircle(
      center,
      reactorRadius * (0.36 + bass * 0.10),
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.88),
          accent.withValues(alpha: 0.84),
          secondary.withValues(alpha: 0.35),
        ], stops: const [
          0.0,
          0.38,
          1.0
        ]).createShader(
          Rect.fromCircle(center: center, radius: reactorRadius * 0.62),
        ),
    );
  }

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
