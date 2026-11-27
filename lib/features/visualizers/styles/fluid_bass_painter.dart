import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';

class FluidBassPainter extends VisualizerPainter {
  FluidBassPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height);
    if (minDim <= 0 || data.values.isEmpty) return;
    final bass = (data.bass * config.bassBoost).clamp(0.0, 1.0).toDouble();
    final energy = data.energy;
    final lowBandCount = math.max(1, data.values.length ~/ 4);
    var lowBandEnergy = 0.0;
    for (var i = 0; i < lowBandCount; i++) {
      lowBandEnergy += data.values[i];
    }
    lowBandEnergy = (lowBandEnergy / lowBandCount).clamp(0.0, 1.0).toDouble();

    // The outer contour follows the low-frequency bands; inner contours carry the bass pulse.
    final blobCount = 5;
    for (var blob = 0; blob < blobCount; blob++) {
      final t = blob / (blobCount - 1);
      final baseRadius = minDim * (0.075 + t * 0.155) * (0.90 + lowBandEnergy * 0.18);
      final blobBass = (bass * (0.72 + t * 0.28) * (0.75 + lowBandEnergy * 0.25))
          .clamp(0.0, 1.0)
          .toDouble();

      final points = <Offset>[];
      final segments = 20 + blob * 4;

      for (var i = 0; i <= segments; i++) {
        final angle = 2 * math.pi * i / segments;
        final wave1 = math.sin(angle * 3 + data.phase * 2 + blob) * 0.15;
        final wave2 = math.sin(angle * 5 - data.phase * 1.5 + blob * 2) * 0.10;
        final bassPulse = math.sin(data.beatPhase + blob * 0.8) * blobBass * 0.22;

        final radius = baseRadius * (1 + wave1 + wave2 + bassPulse);
        final x = center.dx + math.cos(angle) * radius;
        final y = center.dy + math.sin(angle) * radius * (0.84 + energy * 0.16);

        points.add(Offset(x, y));
      }

      final color = colorAt(t, energy: energy, bass: bass);
      final opacity = (0.12 + blobBass * 0.24 + lowBandEnergy * 0.12 + energy * 0.06)
          .clamp(0.0, 0.62)
          .toDouble();

      if (config.glow) {
        canvas.drawPath(
          smoothPath(points)..close(),
          Paint()
            ..color = color.withValues(alpha: opacity * 0.4)
            ..style = PaintingStyle.fill
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius * (0.55 + t * 0.25)),
        );
      }

      canvas.drawPath(
        smoothPath(points)..close(),
        Paint()
          ..color = color.withValues(alpha: opacity * 0.6)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        smoothPath(points)..close(),
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1 + bass * 1.6,
      );
    }

    // Center bass core
    final coreSize = minDim * 0.035 * (1 + bass * 1.35);
    final pulseRing = coreSize * (1.7 + ((data.beatPhase * 0.5) % 0.5));
    canvas.drawCircle(
      center,
      pulseRing,
      Paint()
        ..color = colorAt(0.5, energy: energy, bass: bass).withValues(alpha: 0.12 + bass * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + bass,
    );
    canvas.drawCircle(
      center,
      coreSize,
      glowingPaint(colorAt(0.5, energy: energy, bass: bass)),
    );
  }
}
