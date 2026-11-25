import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class FractalBloomPainter extends VisualizerPainter {
  FractalBloomPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);

    final width = size.width;
    final height = size.height;
    final minDim = math.min(width, height);
    final center = Offset(width * 0.5, height * 0.57);
    final bands = data.values;
    final history = data.history;
    final bandCount = bands.length;

    double bandAt(double position) {
      if (bandCount == 0) return 0;
      final index = (position * (bandCount - 1)).round().clamp(0, bandCount - 1);
      return bands[index].isFinite ? bands[index].clamp(0.0, 1.0).toDouble() : 0;
    }

    double safe(double value) => value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0;

    final bass = safe(data.bass);
    final mid = safe(data.mid);
    final high = safe(data.high);
    final energy = safe(data.energy);
    final intensity = config.intensity.clamp(0.3, 2.5).toDouble();
    final bassBoost = config.bassBoost.clamp(0.5, 3.0).toDouble();
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final opening = 0.82 + 0.18 * math.sin(phase * 0.55);
    final rotation = math.sin(phase * 0.22) * 0.09;
    final rootLength = minDim * (0.19 + bass * 0.045 * bassBoost) *
        (0.92 + bandAt(0.08) * 0.20) *
        (0.88 + 0.12 * intensity);

    // Recent history contributes only a small, stable modulation; list bounds
    // are checked before use so a cleared or empty stream is harmless.
    final historyPulse = history.isEmpty || history.last.isEmpty
        ? 0.0
        : safe(history.last[history.last.length ~/ 2]);
    final coreRadius = minDim * (0.018 + bass * 0.012 + historyPulse * 0.004);

    final coreColor = colorAt(0.48, energy: energy, bass: bass);
    canvas.drawCircle(
      center,
      coreRadius * 2.1,
      Paint()
        ..shader = RadialGradient(colors: [
          coreColor.withValues(alpha: 0.16 + energy * 0.10),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: center, radius: coreRadius * 2.1))
        ..blendMode = BlendMode.screen,
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = coreColor.withValues(alpha: 0.45 + energy * 0.25)
        ..style = PaintingStyle.fill,
    );

    void branch(Offset start, double angle, double length, int depth, int seed) {
      if (depth <= 0 || length < minDim * 0.018) return;
      final bandPosition = ((seed * 0.173 + (3 - depth) * 0.29) % 1.0);
      final value = bandAt(bandPosition);
      final end = start + Offset(math.cos(angle), math.sin(angle)) * length;
      final bend = Offset(-math.sin(angle), math.cos(angle)) * (length * (0.035 + mid * 0.025));
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(start.dx + (end.dx - start.dx) * 0.52 + bend.dx,
            start.dy + (end.dy - start.dy) * 0.52 + bend.dy, end.dx, end.dy);
      final t = (0.24 + (3 - depth) * 0.22 + bandPosition * 0.18).clamp(0.0, 1.0).toDouble();
      final color = colorAt(t, energy: energy, bass: bass);
      final alpha = (0.48 + value * 0.28 + high * 0.12).clamp(0.0, 0.86).toDouble();
      final stroke = (0.65 + length / minDim * 2.0).clamp(0.65, 2.0).toDouble();

      if (config.glow && depth >= 2) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: alpha * 0.23)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 2.1
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              (config.glowRadius * 0.24).clamp(1.0, 7.0).toDouble(),
            ),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      if (depth == 1) {
        canvas.drawCircle(
          end,
          minDim * (0.0035 + value * 0.0025),
          Paint()..color = color.withValues(alpha: alpha * 0.78),
        );
        return;
      }

      final spread = (0.39 + high * 0.16 + value * 0.08) * opening;
      final childLength = length * (0.61 + value * 0.12) * opening;
      // Two children per node: maximum 2 + 4 + 8 = 14 branches per stem.
      branch(end, angle - spread, childLength, depth - 1, seed * 2 + 1);
      branch(end, angle + spread, childLength * (0.96 + mid * 0.04), depth - 1, seed * 2 + 2);
    }

    // Four mirrored stems form a calm, upright flower. Three recursive levels
    // yield at most 56 branch segments in total, independent of audio buffers.
    for (var stem = 0; stem < 4; stem++) {
      final side = stem < 2 ? -1.0 : 1.0;
      final paired = stem.isEven ? -1.0 : 1.0;
      final angle = -math.pi / 2 + side * (0.30 + rotation) + paired * rotation * 0.35;
      final length = rootLength * (stem.isEven ? 1.0 : 0.94) *
          (1.0 + bandAt(0.14 + stem * 0.16) * 0.08);
      branch(center, angle, length, 3, stem + 1);
    }

    // A fine, low-contrast basal arc grounds the bloom without competing with it.
    final baseColor = colorAt(0.12, energy: energy, bass: bass);
    final arcRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + minDim * 0.012),
      width: minDim * (0.24 + bass * 0.025),
      height: minDim * 0.075,
    );
    canvas.drawArc(
      arcRect,
      math.pi * 0.12,
      math.pi * 0.76,
      false,
      Paint()
        ..color = baseColor.withValues(alpha: 0.12 + mid * 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}
