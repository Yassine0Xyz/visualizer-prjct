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
    final center = Offset(width * 0.5, height * 0.58);
    final bands = data.values;
    final history = data.history;
    final bandCount = bands.length;

    double bandAt(double position) {
      if (bandCount == 0) return 0;
      final index = (position * (bandCount - 1)).round().clamp(0, bandCount - 1);
      return _unit(bands[index]);
    }

    final bass = _unit(data.bass);
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final energy = _unit(data.energy);
    final intensity = config.intensity.isFinite
        ? config.intensity.clamp(0.3, 2.5).toDouble()
        : 1.0;
    final bassBoost = config.bassBoost.isFinite
        ? config.bassBoost.clamp(0.5, 3.0).toDouble()
        : 1.0;
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final historyPulse = history.isEmpty || history.last.isEmpty
        ? 0.0
        : _unit(history.last[history.last.length ~/ 2]);
    final growthDrive = (energy * 0.38 + bass * 0.18 + mid * 0.22 + high * 0.22)
        .clamp(0.0, 1.0)
        .toDouble();
    final branchDensity = (0.13 + growthDrive * 0.72 + historyPulse * 0.10)
        .clamp(0.12, 0.98)
        .toDouble();
    final maximumDepth = growthDrive > 0.64 ? 5 : growthDrive > 0.27 ? 4 : 3;
    final secondaryStemCount = growthDrive > 0.48 ? 2 : 0;
    final stemCount = 4 + secondaryStemCount;
    final opening = 0.90 + 0.10 * math.sin(phase * 0.42);
    final sway = math.sin(phase * 0.20) * 0.075 + mid * 0.025;
    final rootLength = minDim *
        (0.18 + bass * 0.050 * bassBoost + energy * 0.016) *
        (0.90 + bandAt(0.07) * 0.18) *
        (0.90 + 0.10 * intensity);
    final coreRadius = minDim * (0.017 + bass * 0.011 + historyPulse * 0.004);
    final coreColor = colorAt(0.47 + high * 0.18, energy: energy, bass: bass);

    // A luminous seed and faint growth rings anchor the expanding canopy.
    final haloRect = Rect.fromCircle(center: center, radius: coreRadius * 4.2);
    canvas.drawCircle(
      center,
      coreRadius * 4.2,
      Paint()
        ..shader = RadialGradient(colors: [
          coreColor.withValues(alpha: 0.20 + energy * 0.12),
          coreColor.withValues(alpha: 0.045 + mid * 0.035),
          Colors.transparent,
        ], stops: const [0.0, 0.38, 1.0]).createShader(haloRect)
        ..blendMode = BlendMode.screen,
    );
    for (var ring = 0; ring < 2; ring++) {
      final radius = coreRadius * (2.05 + ring * 1.10 + bass * 0.15);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        phase * (ring.isEven ? 0.16 : -0.12) + ring * math.pi,
        math.pi * (0.82 + high * 0.12),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65 + high * 0.25
          ..color = colorAt(0.22 + ring * 0.42, energy: energy, bass: bass)
              .withValues(alpha: 0.12 + energy * 0.07),
      );
    }
    canvas.drawCircle(
      center,
      coreRadius * 1.1,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.92),
          coreColor.withValues(alpha: 0.70),
          coreColor.withValues(alpha: 0.12),
        ], stops: const [0.0, 0.48, 1.0]).createShader(
          Rect.fromCircle(center: center, radius: coreRadius * 1.1),
        ),
    );

    void drawLeaf(Offset tip, double angle, double length, Color color, double alpha) {
      final direction = Offset(math.cos(angle), math.sin(angle));
      final normal = Offset(-direction.dy, direction.dx);
      final root = tip - direction * (length * 0.18);
      final far = tip + direction * (length * 0.74) + normal * (length * 0.32);
      final near = tip + direction * (length * 0.54) - normal * (length * 0.28);
      final leaf = Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(
          tip.dx + direction.dx * length * 0.36 + normal.dx * length * 0.44,
          tip.dy + direction.dy * length * 0.36 + normal.dy * length * 0.44,
          far.dx,
          far.dy,
        )
        ..quadraticBezierTo(
          tip.dx + direction.dx * length * 0.34,
          tip.dy + direction.dy * length * 0.34,
          near.dx,
          near.dy,
        )
        ..quadraticBezierTo(
          tip.dx - direction.dx * length * 0.08 - normal.dx * length * 0.20,
          tip.dy - direction.dy * length * 0.08 - normal.dy * length * 0.20,
          root.dx,
          root.dy,
        )
        ..close();
      canvas.drawPath(
        leaf,
        Paint()
          ..shader = LinearGradient(
            colors: [color.withValues(alpha: alpha * 0.55), color.withValues(alpha: alpha)],
          ).createShader(Rect.fromPoints(root, far)),
      );
      canvas.drawLine(
        root,
        far,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.18)
          ..strokeWidth = 0.45
          ..strokeCap = StrokeCap.round,
      );
    }

    void branch(
      Offset start,
      double angle,
      double length,
      int depth,
      int seed,
      int stem,
    ) {
      if (depth <= 0 || length < minDim * 0.0105) return;
      final level = maximumDepth - depth;
      final bandPosition = ((seed * 0.173 + (maximumDepth - depth) * 0.29 + stem * 0.11) % 1.0);
      final value = bandAt(bandPosition);
      final end = start + Offset(math.cos(angle), math.sin(angle)) * length;
      final normal = Offset(-math.sin(angle), math.cos(angle));
      final bend = normal * (length * (0.035 + mid * 0.028 + math.sin(phase * 0.34 + seed) * 0.008));
      final control = start + (end - start) * 0.52 + bend;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      final spectral = (0.16 + (maximumDepth - depth) * 0.14 + bandPosition * 0.20 + high * 0.12)
          .clamp(0.0, 1.0)
          .toDouble();
      final color = colorAt(spectral, energy: energy, bass: bass);
      final alpha = (0.42 + value * 0.26 + high * 0.15 + energy * 0.10)
          .clamp(0.0, 0.88)
          .toDouble();
      final stroke = (0.60 + length / minDim * (2.6 + bass * 0.45))
          .clamp(0.52, 2.35)
          .toDouble();

      if (config.glow && depth >= 2 && depth < maximumDepth) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: alpha * (0.18 + energy * 0.08))
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 2.0
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              (config.glowRadius * 0.20).clamp(0.8, 5.5).toDouble(),
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

      if (depth == 1 || length < minDim * 0.024) {
        final leafLength = minDim * (0.012 + high * 0.010 + value * 0.006);
        drawLeaf(end, angle - 0.82, leafLength, color, alpha * (0.70 + branchDensity * 0.25));
        if (value + high * 0.18 > 0.25) {
          drawLeaf(end, angle + 0.90, leafLength * 0.82, colorAt(spectral + 0.12, energy: energy, bass: bass), alpha * 0.72);
        }
        canvas.drawCircle(
          end,
          minDim * (0.0021 + value * 0.0016 + high * 0.0012),
          Paint()..color = Colors.white.withValues(alpha: alpha * (0.24 + high * 0.22)),
        );
        return;
      }

      final spread = (0.34 + high * 0.20 + value * 0.10 +
              math.sin(phase * 0.31 + seed * 0.4) * 0.035) *
          opening;
      final childLength = length * (0.65 + value * 0.10 + bass * 0.035) * opening;
      final childDensity = (branchDensity * (0.68 + value * 0.32 + mid * 0.06))
          .clamp(0.0, 0.99)
          .toDouble();
      final leftRoll = ((seed * 92821 + depth * 68917 + stem * 15731) % 1009) / 1009.0;
      final rightRoll = ((seed * 63851 + depth * 81499 + stem * 9721) % 1013) / 1013.0;
      final forceFirstLevels = level < 2;
      if (forceFirstLevels || leftRoll < childDensity) {
        branch(end, angle - spread, childLength, depth - 1, seed * 2 + 1, stem);
      }
      if (forceFirstLevels || rightRoll < childDensity * (0.86 + high * 0.10)) {
        branch(
          end,
          angle + spread * (0.94 + mid * 0.08),
          childLength * (0.95 + mid * 0.05),
          depth - 1,
          seed * 2 + 2,
          stem,
        );
      }
    }

    // Four primary boughs keep the recognizable mirrored bloom. At energetic
    // moments two shorter side boughs unfold; recursion then thickens the canopy
    // to as many as 186 bounded segments instead of repeating a static shape.
    for (var stem = 0; stem < stemCount; stem++) {
      final isSideStem = stem >= 4;
      final paired = stem.isEven ? -1.0 : 1.0;
      final side = stem < 2 ? -1.0 : 1.0;
      final baseAngle = isSideStem
          ? -math.pi / 2 + (stem == 4 ? -0.88 : 0.88) + sway * 0.35
          : -math.pi / 2 + side * (0.29 + sway) + paired * sway * 0.32;
      final bandMod = bandAt(0.12 + stem * 0.14);
      final length = rootLength *
          (isSideStem ? 0.60 + bandMod * 0.09 : (stem.isEven ? 1.0 : 0.94)) *
          (1.0 + bandMod * 0.10);
      branch(center, baseAngle, length, maximumDepth, stem + 1, stem);
    }

    // A softly lit ground arc suggests the stem base without enclosing the bloom.
    final baseColor = colorAt(0.10, energy: energy, bass: bass);
    final arcRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + minDim * 0.013),
      width: minDim * (0.25 + bass * 0.035 + growthDrive * 0.025),
      height: minDim * 0.073,
    );
    canvas.drawArc(
      arcRect,
      math.pi * 0.12,
      math.pi * 0.76,
      false,
      Paint()
        ..color = baseColor.withValues(alpha: 0.10 + mid * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
