import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class HarmonicSkylinePainter extends VisualizerPainter {
  HarmonicSkylinePainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (!w.isFinite || !h.isFinite || w < 2 || h < 2) return;

    final bands = data.values;
    double safe(double value) =>
        value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
    double sample(int index) {
      if (bands.isEmpty) return 0;
      final i = index.clamp(0, bands.length - 1).toInt();
      final current = safe(bands[i]);
      final previous = data.previousValues;
      if (i >= previous.length) return current;
      return safe(previous[i]) * 0.18 + current * 0.82;
    }

    final energy = safe(data.energy);
    final bass = safe(data.bass);
    final mid = safe(data.mid);
    final high = safe(data.high);
    final bassEnergy = safe(data.bassEnergy);
    final highEnergy = safe(data.highEnergy);
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final beat = data.beatPhase.isFinite ? data.beatPhase : phase;
    final intensity = config.intensity.isFinite
        ? config.intensity.clamp(0.3, 2.5).toDouble()
        : 1.0;
    final boost = config.bassBoost.isFinite
        ? config.bassBoost.clamp(0.5, 3.0).toDouble()
        : 1.0;
    final vanishing = Offset(w * 0.5, h * 0.405);
    final ground = h * 0.82;
    final pulse = 0.5 + 0.5 * math.sin(beat * 1.8);

    paintBackground(canvas, size);

    // A restrained atmospheric veil establishes distance without flattening
    // the silhouettes.
    final hazeRect = Rect.fromLTWH(0, h * 0.24, w, h * 0.42);
    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colorAt(0.61, energy: energy, bass: mid)
                .withValues(alpha: 0.045 + mid * 0.045),
            colorAt(0.43, energy: energy, bass: bass)
                .withValues(alpha: 0.025 + bassEnergy * 0.045),
            Colors.transparent,
          ],
          stops: const [0, 0.42, 0.72, 1],
        ).createShader(hazeRect)
        ..blendMode = BlendMode.screen,
    );

    // Distant towers are few and intentionally centered on the vanishing point.
    final farPaint = Paint()
      ..color = colorAt(0.28, energy: energy, bass: bass)
          .withValues(alpha: 0.20 + mid * 0.07);
    const farCenters = <double>[
      -0.01,
      0.075,
      0.16,
      0.245,
      0.33,
      0.415,
      0.5,
      0.585,
      0.67,
      0.755,
      0.84,
      0.925,
      1.01,
    ];
    for (var i = 0; i < farCenters.length; i++) {
      final t = (i - 6).abs() / 6;
      final x = farCenters[i] * w;
      final towerH = h * (0.065 + 0.15 * t + sample(i * 2) * 0.035);
      final towerW = w * (0.025 + 0.012 * t);
      final rect = Rect.fromLTWH(
          x - towerW / 2, vanishing.dy - towerH, towerW, towerH + h * 0.015);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(w * 0.004)), farPaint);
      if (i % 2 == 0 && w > 100 && h > 100) {
        final light = Paint()
          ..color = colorAt(0.74, energy: high, bass: bass)
              .withValues(alpha: 0.16 + highEnergy * 0.12);
        for (var row = 0; row < 3; row++) {
          final yy = vanishing.dy - towerH + towerH * (0.28 + row * 0.2);
          canvas.drawRect(
              Rect.fromLTWH(x - towerW * 0.12, yy, towerW * 0.24, h * 0.004),
              light);
        }
      }
    }

    // Foreground city: controlled blocks with a stepped height envelope.
    const blocks = 19;
    final step = w / blocks;
    final silhouette = Path()..moveTo(0, ground);
    final roofs = <double>[];
    final centers = <double>[];
    for (var i = 0; i < blocks; i++) {
      final x0 = i * step;
      final centerDist = ((i + 0.5) / blocks - 0.5).abs() * 2;
      final architecture = 0.12 + 0.23 * centerDist;
      final spectrum = sample(i * (bands.isEmpty ? 0 : bands.length) ~/ blocks);
      final height = h *
          (architecture + spectrum * 0.075 + bassEnergy * 0.035) *
          intensity *
          (0.92 + 0.08 * boost.clamp(0.5, 1.8));
      final roof =
          (ground - height).clamp(h * 0.22, ground - h * 0.06).toDouble();
      final inset = step * 0.12;
      final left = x0 + inset;
      final right = x0 + step * 0.88;
      roofs.add(roof);
      centers.add((left + right) * 0.5);
      silhouette
        ..lineTo(x0, ground)
        ..lineTo(left, ground)
        ..lineTo(left, roof + height * 0.12)
        ..lineTo(left + (right - left) * 0.08, roof + height * 0.12)
        ..lineTo(left + (right - left) * 0.08, roof)
        ..lineTo(right - (right - left) * 0.08, roof)
        ..lineTo(right - (right - left) * 0.08, roof + height * 0.12)
        ..lineTo(right, roof + height * 0.12)
        ..lineTo(right, ground);
    }
    silhouette
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final cityRect = Rect.fromLTWH(0, h * 0.2, w, h * 0.8);
    canvas.drawPath(
      silhouette,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorAt(0.39, energy: high, bass: mid).withValues(alpha: 0.96),
            colorAt(0.23, energy: energy, bass: bass).withValues(alpha: 0.96),
            const Color(0xFF050712),
          ],
          stops: const [0, 0.46, 1],
        ).createShader(cityRect),
    );

    // A few fine facade seams give scale and reinforce the perspective.
    final seamPaint = Paint()
      ..color = colorAt(0.5, energy: mid, bass: bass).withValues(alpha: 0.10)
      ..strokeWidth = math.max(0.55, math.min(0.9, w / 700));
    for (var i = 0; i < blocks; i += 2) {
      final x = centers[i];
      canvas.drawLine(Offset(x, roofs[i] + h * 0.035),
          Offset(x, ground - h * 0.025), seamPaint);
    }

    // Ordered perspective lanes converge cleanly at the horizon; bass controls
    // their restrained brightness and treble adds a subtle moving shimmer.
    final lane = Paint()
      ..color = colorAt(0.58, energy: energy, bass: bass)
          .withValues(alpha: 0.16 + bassEnergy * (0.13 + pulse * 0.08))
      ..strokeWidth = math.max(0.7, math.min(1.25, w / 480));
    for (var i = 0; i <= 8; i++) {
      final bottomX = w * i / 8;
      canvas.drawLine(vanishing, Offset(bottomX, h * 0.98), lane);
    }
    final cross = Paint()
      ..color = colorAt(0.68, energy: high, bass: bass)
          .withValues(alpha: 0.10 + highEnergy * 0.12)
      ..strokeWidth = 0.65;
    for (var row = 1; row <= 5; row++) {
      final t = row / 6;
      final y = vanishing.dy + (h * 0.98 - vanishing.dy) * t * t;
      canvas.drawLine(Offset(w * (0.5 - 0.49 * t), y),
          Offset(w * (0.5 + 0.49 * t), y), cross);
    }

    // Roof beacons and sparse musical windows, with deterministic audio-driven
    // luminance rather than random flicker.
    final windowPaint = Paint();
    for (var i = 1; i < blocks; i += 2) {
      final roof = roofs[i];
      final x = centers[i];
      final twinkle = 0.72 + 0.28 * math.sin(phase * 0.65 + i * 1.71);
      final alpha = (0.18 + energy * 0.20 + highEnergy * 0.12) * twinkle;
      windowPaint.color =
          colorAt(0.77, energy: high, bass: mid).withValues(alpha: alpha);
      final rows = roof < ground - h * 0.22 ? 3 : 2;
      for (var row = 0; row < rows; row++) {
        final y = roof + h * (0.085 + row * 0.055);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                x - step * 0.10, y, step * 0.20, math.max(1.0, h * 0.008)),
            const Radius.circular(1),
          ),
          windowPaint,
        );
      }
      canvas.drawCircle(
          Offset(x, roof - h * 0.009), math.max(0.8, w * 0.0018), windowPaint);
    }

    // Horizon glow binds the city layers without a hard bright outline.
    final horizon = Paint()
      ..color = colorAt(0.56, energy: energy, bass: bass)
          .withValues(alpha: 0.19 + pulse * bassEnergy * 0.13)
      ..strokeWidth = math.max(0.7, math.min(1.2, h / 380));
    canvas.drawLine(Offset(0, vanishing.dy), Offset(w, vanishing.dy), horizon);
  }
}
