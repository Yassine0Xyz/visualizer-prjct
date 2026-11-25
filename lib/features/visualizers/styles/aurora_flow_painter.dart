import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class AuroraFlowPainter extends VisualizerPainter {
  AuroraFlowPainter(super.data, super.config, super.theme);

  double _unit(double value) => value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);

    final bass = _unit(data.bass) * config.bassBoost.clamp(0.5, 3.0).toDouble();
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final energy = _unit(data.energy);
    final intensity = config.intensity.clamp(0.3, 2.5).toDouble();
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final values = data.values;
    final bandCount = values.length;
    final width = size.width;
    final height = size.height;
    final samples = width < 480 ? 28 : 40;
    final ribbons = 4;
    final step = width / (samples - 1);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var ribbon = 0; ribbon < ribbons; ribbon++) {
      final points = <Offset>[];
      final baseY = height * (0.32 + ribbon * 0.105);
      final amplitude = height * (0.035 + bass * 0.055) * intensity;
      final ribbonPhase = phase * (0.19 + ribbon * 0.025) + ribbon * 1.43;
      for (var i = 0; i < samples; i++) {
        final x = i * step;
        final u = i / (samples - 1);
        final index = bandCount == 0
            ? 0
            : ((u * (bandCount - 1)).round()).clamp(0, bandCount - 1);
        final band = bandCount == 0 ? 0.0 : _unit(values[index]);
        final envelope = math.sin(math.pi * u).abs();
        final broad = math.sin(u * math.pi * 2.0 + ribbonPhase) * amplitude;
        final undulation = math.sin(u * math.pi * (2.2 + ribbon * 0.35) - phase * 0.31 + ribbon) *
            height * (0.018 + mid * 0.035) * intensity;
        final spectral = band * height * 0.035;
        final ripple = math.sin(u * math.pi * 13.0 + phase * 0.72 + ribbon * 0.8) *
            height * (0.002 + high * 0.009) * intensity;
        points.add(Offset(x, baseY + (broad + undulation + spectral + ripple) * envelope));
      }

      final path = smoothPath(points);
      final color = colorAt((ribbon + 0.7) / ribbons, energy: energy, bass: bass);
      final widthScale = height * (0.065 + bass * 0.018) * intensity;
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = widthScale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorAt((ribbon + 0.45) / ribbons, energy: energy).withValues(alpha: 0.035),
            color.withValues(alpha: 0.19 + energy * 0.10),
            colorAt((ribbon + 1.0) / ribbons, bass: bass).withValues(alpha: 0.045),
          ],
        ).createShader(Offset.zero & size)
        ..blendMode = BlendMode.screen;
      if (config.glow && config.glowRadius > 0) {
        glowPaint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          (config.glowRadius * 0.42).clamp(1.0, 12.0).toDouble(),
        );
      }
      canvas.drawPath(path, glowPaint);

      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, height * 0.0025)
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withValues(alpha: 0.18),
            colorAt((ribbon + 0.55) / ribbons, energy: energy, bass: bass)
                .withValues(alpha: 0.44 + energy * 0.15),
            color.withValues(alpha: 0.16),
          ],
        ).createShader(Offset.zero & size)
        ..blendMode = BlendMode.screen;
      canvas.drawPath(path, corePaint);
    }
    canvas.restore();
  }
}
