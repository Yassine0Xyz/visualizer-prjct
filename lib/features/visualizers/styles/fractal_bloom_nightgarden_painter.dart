import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';
import 'fractal_bloom_painter.dart';

/// A night-garden Fractal Bloom variation with audio-reactive petal accents.
class FractalBloomNightGardenPainter extends VisualizerPainter {
  FractalBloomNightGardenPainter(super.data, super.config, super.theme);

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    FractalBloomPainter(data, config, theme).paint(canvas, size);
    if (!size.width.isFinite || !size.height.isFinite || size.isEmpty) return;

    final minDimension = math.min(size.width, size.height);
    if (minDimension < 2) return;
    final center = Offset(size.width * 0.5, size.height * 0.58);
    final energy = _unit(data.energy);
    final bass = _unit(data.bass);
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final phase = data.phase.isFinite ? data.phase : 0.0;

    // Sample stable low/high spectrum anchors without assuming a non-empty list.
    final bands = data.values;
    final bandCount = bands.length;
    double bandAt(double fraction) {
      if (bandCount == 0) return 0;
      final index = (fraction * (bandCount - 1)).round();
      return _unit(bands[index]);
    }

    final lowBand = bandAt(0.08);
    final trebleBand = bandAt(0.88);
    final drive = (energy * 0.42 + bass * 0.27 + high * 0.18 + mid * 0.13)
        .clamp(0.0, 1.0)
        .toDouble();
    final petalCount = 8 + (high * 4).round();
    final bloomRadius = minDimension *
        (0.105 + bass * 0.030 + lowBand * 0.012 + energy * 0.014);
    final sway = math.sin(phase * 0.22) * (0.018 + mid * 0.014);
    final width = minDimension * (0.010 + energy * 0.0025);
    final glowRadius = config.glowRadius.isFinite
        ? config.glowRadius.clamp(0.0, 24.0).toDouble()
        : 0.0;

    // A restrained, offset halo adds depth while leaving the branching silhouette clear.
    final auraRadius = bloomRadius * (1.35 + bass * 0.12);
    if (config.glow && glowRadius > 0) {
      final auraRect = Rect.fromCircle(center: center, radius: auraRadius);
      canvas.drawCircle(
        center,
        auraRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              colorAt(0.62 + high * 0.12, energy: energy, bass: bass)
                  .withValues(alpha: 0.065 + drive * 0.045),
              Colors.transparent,
            ],
          ).createShader(auraRect)
          ..blendMode = BlendMode.screen,
      );
    }

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.screen;
    final seedPaint = Paint();

    for (var i = 0; i < petalCount; i++) {
      final fraction = i / petalCount;
      final angle =
          math.pi * 2 * fraction + phase * (0.014 + high * 0.008) + sway;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final side = Offset(-direction.dy, direction.dx);
      final localDrive =
          (drive * 0.72 + bandAt((0.12 + fraction * 0.72) % 1.0) * 0.28)
              .clamp(0.0, 1.0)
              .toDouble();
      final pulse = 1 +
          math.sin(phase * (0.16 + bass * 0.05) + i * 1.37) *
              (0.018 + energy * 0.022 + lowBand * 0.012);
      final tipRadius = bloomRadius * pulse;
      final baseRadius = bloomRadius * (0.31 + mid * 0.018);
      final base = center + direction * baseRadius;
      final tip = center + direction * tipRadius;
      final control = (base + tip) * 0.5;
      final petalWidth = width * (0.85 + high * 0.45 + trebleBand * 0.16);
      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          control.dx + side.dx * petalWidth,
          control.dy + side.dy * petalWidth,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          control.dx - side.dx * petalWidth * 0.72,
          control.dy - side.dy * petalWidth * 0.72,
          base.dx,
          base.dy,
        )
        ..close();
      final color = colorAt(fraction + 0.12, energy: energy, bass: bass);

      if (config.glow && glowRadius > 0 && localDrive > 0.12) {
        glowPaint
          ..strokeWidth = 2.0 + glowRadius.clamp(0.0, 5.0).toDouble() * 0.35
          ..color = color.withValues(alpha: 0.035 + localDrive * 0.045)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (glowRadius * 0.12).clamp(0.5, 2.6).toDouble(),
          );
        canvas.drawPath(path, glowPaint);
      }
      outlinePaint
        ..strokeWidth = 0.65 + high * 0.28
        ..color = color.withValues(alpha: 0.16 + localDrive * 0.19);
      canvas.drawPath(path, outlinePaint);

      if (i.isEven) {
        final seedPoint =
            center + direction * (baseRadius + (tipRadius - baseRadius) * 0.72);
        final seedRadius =
            minDimension * (0.0017 + trebleBand * 0.0011 + high * 0.0008);
        seedPaint.color = Colors.white
            .withValues(alpha: 0.16 + high * 0.17 + localDrive * 0.08);
        canvas.drawCircle(seedPoint, seedRadius, seedPaint);
        if (config.glow && high > 0.42 && minDimension > 80) {
          final sparkle = minDimension * (0.0024 + high * 0.0022);
          seedPaint.color = color.withValues(alpha: 0.20 + high * 0.16);
          seedPaint.strokeWidth = 0.55;
          canvas.drawLine(seedPoint - Offset(sparkle, 0),
              seedPoint + Offset(sparkle, 0), seedPaint);
          canvas.drawLine(
            seedPoint - Offset(0, sparkle * 0.72),
            seedPoint + Offset(0, sparkle * 0.72),
            seedPaint,
          );
        }
      }
    }

    // Fine, incomplete arcs imply layered petals without boxing in the central bloom.
    final ringColor = colorAt(0.78, energy: energy, bass: bass);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6 + high * 0.24
      ..strokeCap = StrokeCap.round
      ..color = ringColor.withValues(alpha: 0.10 + drive * 0.07);
    for (var ring = 0; ring < 2; ring++) {
      final radius = bloomRadius * (1.12 + ring * 0.16 + bass * 0.025);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final start = phase * (ring == 0 ? 0.035 : -0.026) + ring * math.pi;
      canvas.drawArc(
          rect, start, math.pi * (0.66 + high * 0.12), false, ringPaint);
    }

    final coreColor = colorAt(0.56 + high * 0.16, energy: energy, bass: bass);
    final coreRadius = minDimension * (0.0045 + bass * 0.003 + energy * 0.0015);
    if (config.glow && glowRadius > 0) {
      final haloRadius = coreRadius * 3.4;
      final haloRect = Rect.fromCircle(center: center, radius: haloRadius);
      canvas.drawCircle(
        center,
        haloRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              coreColor.withValues(alpha: 0.27 + energy * 0.12),
              coreColor.withValues(alpha: 0.08 + bass * 0.04),
              Colors.transparent,
            ],
            stops: const [0.0, 0.38, 1.0],
          ).createShader(haloRect)
          ..blendMode = BlendMode.screen,
      );
    }
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.72 + high * 0.18),
            coreColor.withValues(alpha: 0.68),
            coreColor.withValues(alpha: 0.12),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );
  }
}
