import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class OrbitingParticlesPainter extends VisualizerPainter {
  OrbitingParticlesPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final minDimension = math.min(size.width, size.height);
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final energy = data.energy.isFinite ? data.energy.clamp(0.0, 1.0).toDouble() : 0.0;
    final bass = data.bass.isFinite ? data.bass.clamp(0.0, 1.0).toDouble() : 0.0;
    final mid = data.mid.isFinite ? data.mid.clamp(0.0, 1.0).toDouble() : 0.0;
    final high = data.high.isFinite ? data.high.clamp(0.0, 1.0).toDouble() : 0.0;
    final intensity = config.intensity.isFinite
        ? config.intensity.clamp(0.3, 2.5).toDouble()
        : 1.0;
    final bassBoost = config.bassBoost.isFinite
        ? config.bassBoost.clamp(0.5, 3.0).toDouble()
        : 1.0;
    final bassDrive = (bass * bassBoost).clamp(0.0, 2.0).toDouble();
    final bands = data.values;
    final trackCount = 4;
    const satelliteCount = 40;

    // Fine, dim orbit lines establish a precise orbital instrument-like geometry.
    for (var track = 0; track < trackCount; track++) {
      final t = track / (trackCount - 1);
      final baseRx = minDimension * (0.17 + t * 0.24);
      final baseRy = baseRx * (0.48 + (track % 2) * 0.12);
      final eccentricityPulse = 1.0 + bassDrive * 0.012;
      final rotation = phase * (track.isEven ? 0.12 : -0.095) + track * 0.37;
      final rect = Rect.fromCenter(
        center: center,
        width: baseRx * 2 * eccentricityPulse,
        height: baseRy * 2,
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.translate(-center.dx, -center.dy);
      final color = colorAt(0.16 + t * 0.68, energy: energy, bass: bass);
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75
          ..color = color.withValues(alpha: 0.10 + t * 0.035),
      );
      canvas.restore();
    }

    // Satellites are fixed in count and placement; only phase determines motion.
    for (var i = 0; i < satelliteCount; i++) {
      final track = i % trackCount;
      final orbit = i ~/ trackCount;
      final t = track / (trackCount - 1);
      final bandValue = bands.isEmpty
          ? 0.0
          : bands[(i * 7 + track * 11) % bands.length].isFinite
              ? bands[(i * 7 + track * 11) % bands.length].clamp(0.0, 1.0).toDouble()
              : 0.0;
      final harmonic = 1.0 + (orbit % 4) * 0.055;
      final angularSpeed = (0.20 + (3 - track) * 0.035 + bandValue * 0.045) * harmonic;
      final angle = (i * 2.399963229728653) + phase * angularSpeed * (track.isEven ? 1 : -1);
      final radiusX = minDimension * (0.17 + t * 0.24) * (1.0 + bassDrive * 0.012);
      final radiusY = radiusX * (0.48 + (track % 2) * 0.12);
      final trackRotation = phase * (track.isEven ? 0.12 : -0.095) + track * 0.37;
      final local = Offset(math.cos(angle) * radiusX, math.sin(angle) * radiusY);
      final satellite = center + Offset(
        local.dx * math.cos(trackRotation) - local.dy * math.sin(trackRotation),
        local.dx * math.sin(trackRotation) + local.dy * math.cos(trackRotation),
      );

      final spectral = (0.12 + t * 0.56 + high * 0.16 + bandValue * 0.16).clamp(0.0, 1.0).toDouble();
      final color = colorAt(spectral, energy: energy, bass: bass);
      final brightness = (0.26 + bandValue * 0.34 + mid * 0.12 + energy * 0.12)
          .clamp(0.16, 0.78)
          .toDouble();
      final particleRadius = (0.75 + bandValue * 1.15 + (track == 0 ? bassDrive * 0.25 : 0.0))
          .clamp(0.65, 2.4)
          .toDouble();

      if (config.glow && (i % 3 == 0 || particleRadius > 1.8)) {
        final blur = (config.glowRadius * 0.18).clamp(0.6, 4.0).toDouble();
        canvas.drawCircle(
          satellite,
          particleRadius * 1.8,
          Paint()
            ..color = color.withValues(alpha: brightness * 0.16)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
        );
      }
      canvas.drawCircle(
        satellite,
        particleRadius,
        Paint()..color = color.withValues(alpha: brightness),
      );
    }

    // A restrained stellar core: soft aura, warm-white point, and fine corona.
    final coreRadius = minDimension * (0.018 + (bassDrive * 0.002).clamp(0.0, 0.006));
    final coreColor = colorAt(0.58 + high * 0.22, energy: energy, bass: bass);
    if (config.glow) {
      canvas.drawCircle(
        center,
        coreRadius * (2.4 + energy * 0.5),
        Paint()
          ..color = coreColor.withValues(alpha: 0.22 + energy * 0.08)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (config.glowRadius * 0.35).clamp(1.0, 8.0).toDouble(),
          ),
      );
    }
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.96), coreColor.withValues(alpha: 0.9)],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );
    canvas.drawCircle(
      center,
      coreRadius * 1.55,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = coreColor.withValues(alpha: 0.35 + energy * 0.12),
    );
  }
}
