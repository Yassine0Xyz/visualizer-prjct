import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class LissajousStereoPainter extends VisualizerPainter {
  LissajousStereoPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final minDimension = math.min(size.width, size.height);
    final left = data.waveformLeft;
    final right = data.waveformRight;
    final sampleCount = math.min(left.length, right.length);
    final safeEnergy = data.energy.isFinite ? data.energy.clamp(0.0, 1.0).toDouble() : 0.0;
    final safeBass = data.bass.isFinite ? data.bass.clamp(0.0, 1.0).toDouble() : 0.0;
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final beat = data.beatPhase.isFinite ? data.beatPhase : 0.0;

    // Restrained coordinate frame: the trace remains the visual focus.
    final gridColor = colorAt(0.52, energy: safeEnergy, bass: safeBass);
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.11)
      ..strokeWidth = 0.7;
    final gridRadius = minDimension * 0.34;
    canvas.drawLine(Offset(center.dx - gridRadius, center.dy), Offset(center.dx + gridRadius, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, center.dy - gridRadius), Offset(center.dx, center.dy + gridRadius), gridPaint);
    canvas.drawCircle(center, gridRadius, gridPaint..style = PaintingStyle.stroke);
    canvas.drawCircle(center, 2.0, Paint()..color = gridColor.withValues(alpha: 0.24));

    if (sampleCount < 2) return;

    final maxSamples = math.min(sampleCount, 256);
    final stride = sampleCount > maxSamples ? (sampleCount / maxSamples).ceil() : 1;
    final amplitude = minDimension * (0.37 + safeBass * 0.035 * config.bassBoost);
    final intensity = config.intensity.isFinite ? config.intensity.clamp(0.3, 2.5).toDouble() : 1.0;
    final rotation = math.sin(phase * 0.34) * 0.035;
    final cosine = math.cos(rotation);
    final sine = math.sin(rotation);

    // Three phase-offset copies suggest phosphor persistence without duplicating
    // the signal as a linear scope. Each loop is an X/Y stereo sample pairing.
    for (var pass = 2; pass >= 0; pass--) {
      final phaseOffset = pass == 0 ? 0.0 : math.sin(phase * 0.55 + pass * 1.7) * 0.08;
      final points = <Offset>[];
      for (var i = 0; i < sampleCount && points.length < maxSamples; i += stride) {
        final xValue = left[i];
        final yValue = right[i];
        if (!xValue.isFinite || !yValue.isFinite) continue;
        final x = xValue.clamp(-1.5, 1.5).toDouble();
        final y = yValue.clamp(-1.5, 1.5).toDouble();
        final shiftedX = x * math.cos(phaseOffset) - y * math.sin(phaseOffset);
        final shiftedY = x * math.sin(phaseOffset) + y * math.cos(phaseOffset);
        points.add(center + Offset(
          (shiftedX * cosine - shiftedY * sine) * amplitude,
          (shiftedX * sine + shiftedY * cosine) * amplitude,
        ));
      }
      if (points.length < 2) continue;

      final isMain = pass == 0;
      final path = smoothPath(points);
      final paletteT = (0.42 + pass * 0.17 + math.sin(phase * 0.3) * 0.04).clamp(0.0, 1.0).toDouble();
      final color = colorAt(paletteT, energy: safeEnergy, bass: safeBass);
      final alpha = isMain
          ? (0.66 + safeEnergy * 0.25).clamp(0.0, 0.92).toDouble()
          : (0.075 + safeEnergy * 0.07) / (pass + 0.35);
      final width = isMain ? (1.15 + intensity * 0.4) : 0.9;

      if (config.glow && isMain) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: alpha * 0.36)
            ..style = PaintingStyle.stroke
            ..strokeWidth = width + 2.2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius.clamp(0.0, 32.0) * 0.55)
            ..blendMode = BlendMode.screen,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // A quiet phase-tinted center glint anchors the stereo field.
    final glint = colorAt((0.56 + beat * 0.04).clamp(0.0, 1.0).toDouble(), energy: safeEnergy);
    canvas.drawCircle(center, 1.4 + safeEnergy * 1.5, Paint()..color = glint.withValues(alpha: 0.45));
  }
}
