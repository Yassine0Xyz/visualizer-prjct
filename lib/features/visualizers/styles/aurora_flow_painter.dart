import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class AuroraFlowPainter extends VisualizerPainter {
  AuroraFlowPainter(super.data, super.config, super.theme);

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;

  double _safe(double value, double fallback) =>
      value.isFinite ? value : fallback;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || size.width <= 0 || size.height <= 0) return;
    paintBackground(canvas, size);

    final bassBoost = _safe(config.bassBoost, 1.0).clamp(0.5, 3.0).toDouble();
    final bass = (_unit(data.bass) * bassBoost).clamp(0.0, 1.0).toDouble();
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final energy = _unit(data.energy);
    final intensity = _safe(config.intensity, 1.0).clamp(0.3, 2.5).toDouble();
    final phase = _safe(data.phase, 0.0);
    final bands = data.values;
    final bandCount = bands.length;
    final width = size.width;
    final height = size.height;
    final minDim = math.min(width, height);
    final samples = width < 360 ? 24 : (width < 700 ? 36 : 48);
    final step = width / (samples - 1);
    final centerY = height * 0.50;

    // Smooth interpolation keeps spectral movement fluid without inventing
    // state: VisualizerData already supplies temporally filtered band values.
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var ribbon = 0; ribbon < 4; ribbon++) {
      final layer = ribbon / 3;
      final depth = (ribbon - 1.5) / 1.5;
      final points = <Offset>[];
      final laneY = centerY + depth * height * 0.115;
      final amplitude =
          height * (0.045 + bass * 0.10 + mid * 0.025) * intensity;
      final ribbonPhase = phase * (0.16 + ribbon * 0.025) + ribbon * 1.47;

      for (var i = 0; i < samples; i++) {
        final u = i / (samples - 1);
        final x = i * step;
        final envelope = math.pow(math.sin(math.pi * u), 0.72).toDouble();
        var spectral = 0.0;
        if (bandCount > 0) {
          final position = u * (bandCount - 1);
          final lower = position.floor().clamp(0, bandCount - 1);
          final upper = (lower + 1).clamp(0, bandCount - 1);
          final fraction = position - lower;
          spectral = _unit(bands[lower]) * (1 - fraction) +
              _unit(bands[upper]) * fraction;
        }

        final broad =
            math.sin(u * math.pi * (2.0 + layer * 0.7) + ribbonPhase) *
                (0.20 + bass * 0.55);
        final rolling =
            math.sin(u * math.pi * 3.0 - phase * 0.27 + ribbon * 0.9) *
                (0.10 + mid * 0.30);
        final spectralLift = (spectral - 0.22) * (0.24 + high * 0.16);
        final glimmer =
            math.sin(u * math.pi * 15.0 + phase * 0.62 + ribbon) * high * 0.045;
        points.add(Offset(
          x,
          laneY +
              (broad + rolling + spectralLift + glimmer) * amplitude * envelope,
        ));
      }

      final path = smoothPath(points);
      final color = colorAt(0.13 + layer * 0.70 + high * 0.06,
          energy: energy, bass: bass);
      final glowWidth = minDim *
          (0.018 + bass * 0.012) *
          (ribbon == 1 || ribbon == 2 ? 1.0 : 0.72);
      if (config.glow && config.glowRadius > 0) {
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = glowWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color.withValues(alpha: 0.075 + energy * 0.055)
          ..blendMode = BlendMode.screen
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (_safe(config.glowRadius, 0).clamp(0.0, 32.0) * 0.28)
                .clamp(1.0, 7.0)
                .toDouble(),
          );
        canvas.drawPath(path, glow);
      }

      final core = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, minDim * (0.0022 + high * 0.001))
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.42 + energy * 0.20),
            colorAt(0.82 - layer * 0.30, energy: energy, bass: bass)
                .withValues(alpha: 0.20 + high * 0.18),
          ],
        ).createShader(Offset.zero & size)
        ..blendMode = BlendMode.screen;
      canvas.drawPath(path, core);
    }

    // A subtle centerline anchors the flowing silhouettes without covering them.
    final horizonY = centerY + height * 0.002;
    final horizon = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          colorAt(0.48, energy: energy, bass: bass)
              .withValues(alpha: 0.10 + bass * 0.10),
          colorAt(0.72, energy: energy).withValues(alpha: 0.08 + high * 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, horizonY, width, 1))
      ..strokeWidth = math.max(0.8, minDim * (0.0013 + high * 0.0007))
      ..blendMode = BlendMode.screen;
    canvas.drawLine(Offset(width * 0.08, horizonY),
        Offset(width * 0.92, horizonY), horizon);
    canvas.restore();
  }
}
