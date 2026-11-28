import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// A refined orbital system centered on a responsive luminous nucleus.
class OrbitingParticlesHaloPainter extends VisualizerPainter {
  OrbitingParticlesHaloPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
    final minDimension = math.min(size.width, size.height);
    if (!minDimension.isFinite || minDimension <= 0) return;

    paintBackground(canvas, size);
    final center = size.center(Offset.zero);
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final smoothness = _unit(config.smoothness);
    final response = 1.0 - smoothness * 0.52;
    final energy = _unit(data.energy) * response;
    final bass = _unit(data.bass) * response;
    final mid = _unit(data.mid) * response;
    final high = _unit(data.high) * response;
    final bassBoost = config.bassBoost.isFinite
        ? config.bassBoost.clamp(0.5, 3.0).toDouble()
        : 1.0;
    final bassDrive = (bass * bassBoost).clamp(0.0, 2.0).toDouble();
    final intensity = config.intensity.isFinite
        ? config.intensity.clamp(0.3, 2.5).toDouble()
        : 1.0;
    final bands = data.values;

    // Three separated orbital planes; the middle track is intentionally quiet.
    for (var lane = 0; lane < 3; lane++) {
      final depth = lane / 2;
      final rx = minDimension *
          (0.235 + depth * 0.135) *
          (1.0 + bassDrive * (lane == 0 ? 0.018 : 0.008));
      final ry = rx * (0.42 + depth * 0.10 + high * 0.025);
      final tilt = phase * (lane == 1 ? -0.038 : 0.045) + lane * 0.64;
      final oval = Rect.fromCenter(
        center: Offset.zero,
        width: rx * 2,
        height: ry * 2,
      );
      final color = colorAt(0.26 + depth * 0.48, energy: energy, bass: bass);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(tilt);
      canvas.drawOval(
        oval,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lane == 1 ? 0.65 : 0.9
          ..color = color.withValues(alpha: 0.075 + energy * 0.045),
      );
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.8 + high * 0.45
        ..color = color.withValues(alpha: 0.18 + high * 0.13 + mid * 0.04);
      canvas.drawArc(
        oval,
        phase * (lane == 1 ? -0.12 : 0.16) + lane * 1.6,
        0.38 + mid * 0.18,
        false,
        arcPaint,
      );
      canvas.restore();
    }

    // Five distinct satellites use separate spectral regions and orbital rates.
    const satelliteCount = 5;
    for (var i = 0; i < satelliteCount; i++) {
      final bandValue = bands.isEmpty
          ? 0.0
          : _unit(
              bands[(i * (bands.length ~/ satelliteCount) + bands.length ~/ 7) %
                  bands.length],
            );
      final lane = i % 3;
      final rx = minDimension *
          (0.255 + lane * 0.052) *
          (1.0 + bassDrive * (lane == 0 ? 0.016 : 0.007));
      final ry = rx * (0.44 + lane * 0.045 + high * 0.025);
      final rotation = phase * (lane == 1 ? -0.038 : 0.045) + lane * 0.64;
      final speed = 0.19 +
          high * 0.11 +
          bandValue * 0.06 +
          (lane == 0 ? bass * 0.025 : 0.0);
      final direction = i == 2 ? -1.0 : 1.0;
      final angle =
          phase * speed * direction + i * math.pi * 2 / satelliteCount;
      final local = Offset(math.cos(angle) * rx, math.sin(angle) * ry);
      final position = center +
          Offset(
            local.dx * math.cos(rotation) - local.dy * math.sin(rotation),
            local.dx * math.sin(rotation) + local.dy * math.cos(rotation),
          );
      final spectral = (0.18 + lane * 0.18 + high * 0.22 + bandValue * 0.24)
          .clamp(0.0, 1.0)
          .toDouble();
      final color = colorAt(spectral, energy: energy, bass: bass);
      final radius = (minDimension *
                  (0.0042 +
                      bandValue * 0.002 +
                      high * 0.0015 +
                      (lane == 0 ? bassDrive * 0.001 : 0.0)))
              .clamp(0.7, math.max(0.7, minDimension * 0.014))
              .toDouble() *
          intensity.clamp(0.7, 1.5).toDouble();

      // Fine luminous wake points backward along the orbit, not a broad trail.
      final tailAngle = angle - direction * 0.09;
      final tailLocal =
          Offset(math.cos(tailAngle) * rx, math.sin(tailAngle) * ry);
      final tail = center +
          Offset(
            tailLocal.dx * math.cos(rotation) -
                tailLocal.dy * math.sin(rotation),
            tailLocal.dx * math.sin(rotation) +
                tailLocal.dy * math.cos(rotation),
          );
      canvas.drawLine(
        tail,
        position,
        Paint()
          ..color = color.withValues(alpha: 0.28 + energy * 0.14)
          ..strokeWidth = 0.55
          ..strokeCap = StrokeCap.round,
      );
      if (config.glow && config.glowRadius > 0) {
        final haloRadius = radius * (2.8 + energy * 0.8);
        final haloBounds =
            Rect.fromCircle(center: position, radius: haloRadius);
        canvas.drawCircle(
          position,
          haloRadius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: 0.17 + energy * 0.10),
                color.withValues(alpha: 0.045),
                Colors.transparent,
              ],
              stops: const [0.0, 0.46, 1.0],
            ).createShader(haloBounds)
            ..blendMode = BlendMode.screen,
        );
      }
      final coreBounds = Rect.fromCircle(center: position, radius: radius);
      canvas.drawCircle(
        position,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.96),
              color.withValues(alpha: 0.92),
              color.withValues(alpha: 0.44),
            ],
            stops: const [0.0, 0.52, 1.0],
          ).createShader(coreBounds),
      );
    }

    // Compact energy nucleus with a breathing corona and restrained bloom.
    final coreRadius =
        minDimension * (0.021 + bassDrive * 0.0028 + mid * 0.001);
    final coreColor = colorAt(0.54 + high * 0.25, energy: energy, bass: bass);
    if (config.glow && config.glowRadius > 0) {
      final bloomRadius = coreRadius * (3.5 + energy * 0.8);
      final bounds = Rect.fromCircle(center: center, radius: bloomRadius);
      canvas.drawCircle(
        center,
        bloomRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              coreColor.withValues(alpha: 0.23 + energy * 0.12),
              coreColor.withValues(alpha: 0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(bounds)
          ..blendMode = BlendMode.screen,
      );
    }
    final nucleusBounds = Rect.fromCircle(center: center, radius: coreRadius);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.98),
            coreColor.withValues(alpha: 0.94),
            coreColor.withValues(alpha: 0.62),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(nucleusBounds),
    );
    canvas.drawCircle(
      center,
      coreRadius * 1.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75 + high * 0.42
        ..color = coreColor.withValues(alpha: 0.28 + energy * 0.16),
    );
    final corona = Rect.fromCircle(center: center, radius: coreRadius * 2.45);
    canvas.drawArc(
      corona,
      phase * 0.28,
      math.pi * (0.42 + high * 0.15),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.8
        ..color = colorAt(0.92, energy: energy, bass: bass)
            .withValues(alpha: 0.24 + high * 0.2),
    );
  }

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
