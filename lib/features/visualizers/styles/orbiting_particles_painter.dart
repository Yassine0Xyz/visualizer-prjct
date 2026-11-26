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
    final energy = _unit(data.energy);
    final bass = _unit(data.bass);
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final intensity = config.intensity.isFinite
        ? config.intensity.clamp(0.3, 2.5).toDouble()
        : 1.0;
    final bassBoost = config.bassBoost.isFinite
        ? config.bassBoost.clamp(0.5, 3.0).toDouble()
        : 1.0;
    final bassDrive = (bass * bassBoost).clamp(0.0, 2.0).toDouble();
    final bands = data.values;
    const trackCount = 5;
    const maximumParticles = 96;

    // Population grows in a continuous band rather than popping in by count.
    final orbitalDensity = (0.22 + energy * 0.43 + bass * 0.14 + mid * 0.11 + high * 0.10)
        .clamp(0.18, 1.0)
        .toDouble();
    final activeParticles = 25 + (orbitalDensity * 71).round();

    // Fine elliptical tracks and short luminous arcs give the field a clear
    // orbital structure without overpowering the particles themselves.
    for (var track = 0; track < trackCount; track++) {
      final t = track / (trackCount - 1);
      final baseRx = minDimension * (0.125 + t * 0.275);
      final baseRy = baseRx * (0.43 + (track % 3) * 0.105);
      final pulse = 1.0 + bassDrive * (track.isEven ? 0.018 : 0.010) + high * 0.008;
      final rotation = phase * (track.isEven ? 0.105 : -0.082) + track * 0.31;
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: baseRx * pulse * 2,
        height: baseRy * 2,
      );
      final color = colorAt(0.10 + t * 0.78, energy: energy, bass: bass);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = track == 2 ? 0.9 : 0.65
          ..color = color.withValues(alpha: 0.075 + energy * 0.035 + t * 0.025),
      );
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + bass * 0.35
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.12 + energy * 0.10 + high * 0.07);
      final arcStart = phase * (track.isEven ? 0.20 : -0.16) + track * 1.47;
      canvas.drawArc(rect, arcStart, 0.38 + energy * 0.20, false, arcPaint);
      canvas.drawArc(
        rect,
        arcStart + math.pi * (1.04 + mid * 0.06),
        0.13 + high * 0.10,
        false,
        arcPaint..color = color.withValues(alpha: 0.07 + high * 0.11),
      );
      canvas.restore();
    }

    Offset orbitPosition(double angle, double radiusX, double radiusY, double rotation) {
      final localX = math.cos(angle) * radiusX;
      final localY = math.sin(angle) * radiusY;
      return center + Offset(
        localX * math.cos(rotation) - localY * math.sin(rotation),
        localX * math.sin(rotation) + localY * math.cos(rotation),
      );
    }

    for (var i = 0; i < maximumParticles; i++) {
      final activation = (activeParticles - i).clamp(0.0, 1.0).toDouble();
      if (activation <= 0) continue;
      final track = i % trackCount;
      final orbit = i ~/ trackCount;
      final t = track / (trackCount - 1);
      final bandIndex = bands.isEmpty ? 0 : (i * 7 + track * 11) % bands.length;
      final bandValue = bands.isEmpty ? 0.0 : _unit(bands[bandIndex]);
      final harmonic = 1.0 + (orbit % 5) * 0.043;
      final angularSpeed = (0.17 + (4 - track) * 0.027 + bandValue * 0.05 + high * 0.015) * harmonic;
      final direction = track.isEven ? 1.0 : -1.0;
      final angle = i * 2.399963229728653 + phase * angularSpeed * direction;
      final radiusX = minDimension * (0.125 + t * 0.275) *
          (1.0 + bassDrive * (track.isEven ? 0.018 : 0.010) + high * 0.008);
      final radiusY = radiusX * (0.43 + (track % 3) * 0.105);
      final trackRotation = phase * (track.isEven ? 0.105 : -0.082) + track * 0.31;
      final satellite = orbitPosition(angle, radiusX, radiusY, trackRotation);
      final tail = orbitPosition(
        angle - direction * angularSpeed * 0.52,
        radiusX,
        radiusY,
        trackRotation,
      );

      final spectral = (0.08 + t * 0.60 + high * 0.17 + bandValue * 0.15)
          .clamp(0.0, 1.0)
          .toDouble();
      final color = colorAt(spectral, energy: energy, bass: bass);
      final twinkle = 0.78 + 0.22 * math.sin(phase * (1.2 + bandValue) + i * 1.73).abs();
      final brightness = (0.20 + bandValue * 0.30 + mid * 0.12 + energy * 0.14) *
          activation * twinkle;
      final particleRadius = (0.72 + bandValue * 1.12 + high * 0.32 +
              (track == 0 ? bassDrive * 0.22 : 0.0))
          .clamp(0.62, 2.55)
          .toDouble() *
          intensity.clamp(0.6, 1.8).toDouble() *
          (0.78 + activation * 0.22);

      // A subtle, tapered wake reveals the orbital direction on selected
      // satellites; it stays deterministic and costs no extra animation state.
      if (i % 2 == 0) {
        canvas.drawLine(
          tail,
          satellite,
          Paint()
            ..color = color.withValues(alpha: brightness * (0.22 + energy * 0.12))
            ..strokeWidth = 0.45 + particleRadius * 0.30
            ..strokeCap = StrokeCap.round,
        );
      }
      if (config.glow && (i % 4 == 0 || particleRadius > 1.8)) {
        final blur = (config.glowRadius * 0.16).clamp(0.5, 3.5).toDouble();
        canvas.drawCircle(
          satellite,
          particleRadius * (1.65 + high * 0.18),
          Paint()
            ..color = color.withValues(alpha: brightness * 0.18)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
        );
      }
      canvas.drawCircle(
        satellite,
        particleRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: brightness.clamp(0.0, 0.9).toDouble()),
              color.withValues(alpha: brightness),
              color.withValues(alpha: brightness * 0.15),
            ],
            stops: const [0.0, 0.36, 1.0],
          ).createShader(Rect.fromCircle(center: satellite, radius: particleRadius)),
      );
    }

    // The nucleus breathes with low frequencies while a rotating corona tracks
    // treble detail, giving the otherwise diffuse orbit a memorable focal point.
    final coreRadius = minDimension * (0.017 + bassDrive * 0.0024 + high * 0.0015);
    final coreColor = colorAt(0.52 + high * 0.24, energy: energy, bass: bass);
    if (config.glow) {
      canvas.drawCircle(
        center,
        coreRadius * (3.0 + energy * 0.55),
        Paint()
          ..color = coreColor.withValues(alpha: 0.14 + energy * 0.10)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (config.glowRadius * 0.31).clamp(0.9, 7.0).toDouble(),
          ),
      );
    }
    canvas.drawCircle(
      center,
      coreRadius * 1.75,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.52 + high * 0.22),
          coreColor.withValues(alpha: 0.36 + energy * 0.20),
          Colors.transparent,
        ], stops: const [0.0, 0.42, 1.0]).createShader(
          Rect.fromCircle(center: center, radius: coreRadius * 1.75),
        )
        ..blendMode = BlendMode.screen,
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.98),
          coreColor.withValues(alpha: 0.92),
        ]).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );
    canvas.drawCircle(
      center,
      coreRadius * 2.05,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 + high * 0.45
        ..color = coreColor.withValues(alpha: 0.22 + energy * 0.18),
    );
    final coronaRect = Rect.fromCircle(center: center, radius: coreRadius * 2.55);
    canvas.drawArc(
      coronaRect,
      phase * 0.3,
      math.pi * (0.36 + high * 0.16),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round
        ..color = colorAt(0.92, energy: energy, bass: bass)
            .withValues(alpha: 0.18 + high * 0.22),
    );
  }

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
