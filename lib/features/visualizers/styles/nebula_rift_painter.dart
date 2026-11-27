import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// A compact deep-space nebula with an audio-reactive stellar rift.
class NebulaRiftPainter extends VisualizerPainter {
  NebulaRiftPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || size.width <= 0 || size.height <= 0) return;
    paintBackground(canvas, size);

    final minDim = math.min(size.width, size.height);
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final intensity = _safe(config.intensity, 1.0).clamp(0.3, 2.5).toDouble();
    final bassBoost = _safe(config.bassBoost, 1.0).clamp(0.5, 3.0).toDouble();
    final energy = _unit(data.energy);
    final bass = (_unit(data.bass) * bassBoost).clamp(0.0, 1.0).toDouble();
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final phase = _safe(data.phase, 0.0);

    // Blend the already-smoothed spectrum with aggregate bands. No temporary
    // collections are created, and empty band arrays safely fall back to bands.
    final bands = data.values;
    final bandCount = bands.length;
    var lowBand = bass;
    var highBand = high;
    if (bandCount > 0) {
      var lowSum = 0.0;
      var highSum = 0.0;
      final lowN = math.min(4, bandCount);
      final highStart = math.max(0, bandCount - 4);
      for (var i = 0; i < lowN; i++) {
        lowSum += _unit(bands[i]);
      }
      for (var i = highStart; i < bandCount; i++) {
        highSum += _unit(bands[i]);
      }
      lowBand = (bass * 0.55 + lowSum / lowN * 0.45).clamp(0.0, 1.0).toDouble();
      highBand = (high * 0.55 + highSum / (bandCount - highStart) * 0.45)
          .clamp(0.0, 1.0)
          .toDouble();
    }

    final coreRadius = minDim * (0.092 + lowBand * 0.027 * intensity);
    // Three restrained cloud lights create a broad, asymmetrical depth field.
    for (var cloud = 0; cloud < 3; cloud++) {
      final angle =
          phase * (cloud.isEven ? 0.018 : -0.014) + cloud * math.pi * 2 / 3;
      final orbit = minDim * (0.16 + cloud * 0.026 + mid * 0.014);
      final cloudCenter = center +
          Offset(math.cos(angle) * orbit, math.sin(angle) * orbit * 0.56);
      final radius = minDim * (0.19 + energy * 0.035);
      final color = colorAt(0.12 + cloud * 0.34 + highBand * 0.10,
          energy: energy, bass: lowBand);
      canvas.drawCircle(
        cloudCenter,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.13 + energy * 0.10),
              color.withValues(alpha: 0.045 + mid * 0.025),
              Colors.transparent,
            ],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(Rect.fromCircle(center: cloudCenter, radius: radius))
          ..blendMode = BlendMode.screen,
      );
    }

    // Perspective accretion disc with independently moving spectral arcs.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.22 + math.sin(phase * 0.035) * 0.025);
    final ringRect = Rect.fromCenter(
      center: Offset.zero,
      width: coreRadius * (5.7 + lowBand * 0.65),
      height: coreRadius * (1.9 + lowBand * 0.24),
    );
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, minDim * 0.0015)
      ..color = colorAt(0.48 + highBand * 0.12, energy: energy, bass: lowBand)
          .withValues(alpha: 0.23 + energy * 0.14);
    canvas.drawOval(ringRect, guidePaint);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, minDim * (0.002 + highBand * 0.0015))
      ..strokeCap = StrokeCap.round
      ..color = colorAt(0.72, energy: energy, bass: lowBand)
          .withValues(alpha: 0.37 + highBand * 0.28);
    if (config.glow) {
      arcPaint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        (_safe(config.glowRadius, 0.0) * 0.16).clamp(0.5, 2.8).toDouble(),
      );
    }
    final arcSweep = math.pi * (0.66 + highBand * 0.28);
    canvas.drawArc(ringRect, phase * 0.12, arcSweep, false, arcPaint);
    canvas.drawArc(
        ringRect, math.pi + phase * -0.08, arcSweep * 0.62, false, arcPaint);
    canvas.restore();

    // A slim spectral silhouette adds structure without covering the core.
    final halfWidth = coreRadius * (0.82 + lowBand * 0.18);
    final top = center.dy - coreRadius * (1.48 + highBand * 0.16);
    final bottom = center.dy + coreRadius * (1.48 + highBand * 0.16);
    final wobble = math.sin(phase * 0.06) * coreRadius * 0.12;
    final rift = Path()
      ..moveTo(center.dx + wobble, top)
      ..cubicTo(
          center.dx - halfWidth * 0.78,
          top + coreRadius * 0.48,
          center.dx + halfWidth * 0.62,
          center.dy - coreRadius * 0.22,
          center.dx,
          center.dy)
      ..cubicTo(
          center.dx - halfWidth * 0.60,
          center.dy + coreRadius * 0.23,
          center.dx + halfWidth * 0.72,
          bottom - coreRadius * 0.42,
          center.dx - wobble,
          bottom);
    final riftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.1, minDim * (0.0025 + highBand * 0.0015))
      ..strokeCap = StrokeCap.round
      ..color = colorAt(0.80, energy: energy, bass: lowBand)
          .withValues(alpha: 0.34 + highBand * 0.23);
    canvas.drawPath(rift, riftPaint);

    final horizonRadius = coreRadius * (0.70 + lowBand * 0.10);
    final haloRadius = horizonRadius * 2.1;
    final haloRect = Rect.fromCircle(center: center, radius: haloRadius);
    canvas.drawCircle(
      center,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            colorAt(0.68, energy: energy, bass: lowBand)
                .withValues(alpha: 0.10 + energy * 0.08),
            Colors.transparent,
          ],
          stops: const [0.46, 0.70, 1.0],
        ).createShader(haloRect)
        ..blendMode = BlendMode.screen,
    );
    canvas.drawCircle(
        center, horizonRadius, Paint()..color = const Color(0xFF050611));
    canvas.drawCircle(
      center,
      horizonRadius * 0.94,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, minDim * 0.0018)
        ..color = Colors.white.withValues(alpha: 0.22 + highBand * 0.19),
    );

    // Sparse deterministic stars keep the focal silhouette legible.
    const starCount = 44;
    for (var i = 0; i < starCount; i++) {
      final seed = i + 1;
      final xUnit = ((seed * 73) % 101) / 100.0;
      final yUnit = ((seed * 47 + 19) % 103) / 102.0;
      final twinkle = 0.42 +
          0.58 * math.sin(phase * (0.18 + (i % 5) * 0.025) + i * 1.71).abs();
      final radius = minDim * (0.0009 + (i % 4) * 0.00035 + highBand * 0.00025);
      final starColor = i % 5 == 0
          ? colorAt(0.78, energy: energy, bass: lowBand)
          : Colors.white;
      canvas.drawCircle(
        Offset(xUnit * size.width, yUnit * size.height),
        radius,
        Paint()
          ..color = starColor.withValues(
            alpha: (0.18 + twinkle * 0.42 + highBand * 0.10)
                .clamp(0.0, 0.76)
                .toDouble(),
          ),
      );
    }

    // Opposed jets breathe with low-end energy; treble sharpens their core.
    final jetLength = minDim *
        (0.11 + lowBand * 0.075 + energy * 0.035) *
        intensity.clamp(0.6, 1.5);
    for (var side = -1; side <= 1; side += 2) {
      final start = center + Offset(0, side * horizonRadius * 0.82);
      final end = start + Offset(0, side * jetLength);
      final color =
          colorAt(side < 0 ? 0.84 : 0.18, energy: energy, bass: lowBand);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          start.dx + math.sin(phase * 0.06 + side) * minDim * 0.014,
          (start.dy + end.dy) * 0.52,
          end.dx,
          end.dy,
        );
      final jetPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.9, minDim * (0.0018 + highBand * 0.0018))
        ..strokeCap = StrokeCap.round
        ..color =
            color.withValues(alpha: 0.17 + energy * 0.12 + highBand * 0.08);
      canvas.drawPath(path, jetPaint);
      if (config.glow) {
        final blur =
            (_safe(config.glowRadius, 0.0) * 0.18).clamp(0.5, 3.5).toDouble();
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(3.0, minDim * 0.009)
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.07 + energy * 0.06)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  double _safe(double value, double fallback) =>
      value.isFinite ? value : fallback;

  double _unit(double value) => _safe(value, 0.0).clamp(0.0, 1.0).toDouble();
}
