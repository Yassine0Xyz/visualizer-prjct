import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';
import 'orbiting_particles_painter.dart';

/// A halo-rich Orbiting Particles variation with a few audio-driven satellites.
class OrbitingParticlesHaloPainter extends VisualizerPainter {
  OrbitingParticlesHaloPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    OrbitingParticlesPainter(data, config, theme).paint(canvas, size);
    if (size.isEmpty) return;

    final minDimension = math.min(size.width, size.height);
    if (!minDimension.isFinite || minDimension <= 0) return;
    final center = size.center(Offset.zero);
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final smoothness = _unit(config.smoothness);
    final response = 1.0 - smoothness * 0.58;
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

    // Three delicate elliptical lanes establish depth without duplicating the
    // denser orbital tracks drawn by the base painter.
    for (var lane = 0; lane < 3; lane++) {
      final laneT = lane / 2;
      final rx = minDimension *
          (0.285 + laneT * 0.105) *
          (1.0 + bassDrive * (lane == 0 ? 0.014 : 0.006));
      final ry = rx * (0.46 + laneT * 0.055 + high * 0.025);
      final rotation = phase * (lane.isEven ? 0.052 : -0.039) + lane * 0.61;
      final rect =
          Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
      final color = colorAt(0.24 + laneT * 0.52, energy: energy, bass: bass);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      if (config.glow && config.glowRadius > 0) {
        canvas.drawOval(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4 + lane * 0.35
            ..color = color.withValues(alpha: 0.035 + energy * 0.045)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              (config.glowRadius * 0.16).clamp(0.5, 3.2).toDouble(),
            ),
        );
      }
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lane == 1 ? 0.95 : 0.65
          ..color = color.withValues(alpha: 0.09 + energy * 0.045),
      );
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.0 + high * 0.45
        ..color = color.withValues(alpha: 0.20 + high * 0.12 + energy * 0.06);
      canvas.drawArc(
        rect,
        phase * (0.12 + lane * 0.025) + lane * math.pi * 0.73,
        math.pi * (0.16 + bass * 0.075 + mid * 0.035),
        false,
        arcPaint,
      );
      canvas.restore();
    }

    // Sparse spectral satellites trace the inner lane. Band energy modulates
    // their size and pace; missing/empty band data falls back to safe defaults.
    for (var i = 0; i < 3; i++) {
      final bandValue = bands.isNotEmpty
          ? _unit(bands[(i * 7 + bands.length ~/ 3) % bands.length])
          : 0.0;
      final spectral = (0.16 + i * 0.23 + high * 0.28 + bandValue * 0.25)
          .clamp(0.0, 1.0)
          .toDouble();
      final angularSpeed = 0.085 + high * 0.09 + bandValue * 0.065;
      final angle =
          phase * angularSpeed * (i == 1 ? -1.0 : 1.0) + i * math.pi * 2 / 3;
      final rx = minDimension * (0.30 + i * 0.031) * (1.0 + bassDrive * 0.009);
      final ry = rx * (0.48 + high * 0.028);
      final rotation = phase * (i == 1 ? -0.039 : 0.052) + i * 0.61;
      final localX = math.cos(angle) * rx;
      final localY = math.sin(angle) * ry;
      final position = center +
          Offset(
            localX * math.cos(rotation) - localY * math.sin(rotation),
            localX * math.sin(rotation) + localY * math.cos(rotation),
          );
      final color = colorAt(spectral, energy: energy, bass: bass);
      final maxRadius = math.max(0.5, minDimension * 0.018);
      final radius = (minDimension *
                  (0.0035 +
                      bassDrive * 0.0014 +
                      high * 0.0012 +
                      bandValue * 0.001))
              .clamp(0.5, maxRadius)
              .toDouble() *
          intensity.clamp(0.65, 1.5).toDouble();

      if (config.glow && config.glowRadius > 0) {
        final bloomRadius = radius * (3.4 + energy * 0.7);
        final bloomRect =
            Rect.fromCircle(center: position, radius: bloomRadius);
        canvas.drawCircle(
          position,
          bloomRadius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: 0.16 + energy * 0.08),
                color.withValues(alpha: 0.045 + high * 0.035),
                Colors.transparent,
              ],
              stops: const [0.0, 0.42, 1.0],
            ).createShader(bloomRect)
            ..blendMode = BlendMode.screen,
        );
      }

      final coreRect = Rect.fromCircle(center: position, radius: radius);
      canvas.drawCircle(
        position,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.88),
              color.withValues(alpha: 0.86),
              color.withValues(alpha: 0.36),
            ],
            stops: const [0.0, 0.48, 1.0],
          ).createShader(coreRect),
      );
      canvas.drawCircle(
        position,
        radius * 1.55,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65
          ..color = color.withValues(alpha: 0.30 + high * 0.16),
      );
    }
  }

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
