import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class HarmonicSkylinePainter extends VisualizerPainter {
  HarmonicSkylinePainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);

    final w = size.width;
    final h = size.height;
    final baseY = h * 0.82;
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final intensity = config.intensity.isFinite
        ? config.intensity.clamp(0.3, 2.5).toDouble()
        : 1.0;
    final bassBoost = config.bassBoost.isFinite
        ? config.bassBoost.clamp(0.5, 3.0).toDouble()
        : 1.0;
    final bass = _safe(data.bass);
    final energy = _safe(data.energy);
    final bands = data.values;

    double bandAt(int index) {
      if (bands.isEmpty) return 0;
      final i = index.clamp(0, bands.length - 1).toInt();
      return _safe(bands[i]);
    }

    // A distant, deliberately quiet ridge gives the nearer buildings depth.
    final farPath = Path()..moveTo(0, baseY);
    const farCount = 24;
    for (var i = 0; i <= farCount; i++) {
      final x = w * i / farCount;
      final v = bandAt((i * 3 + bands.length ~/ 5) % math.max(1, bands.length));
      final undulation = math.sin(i * 1.73 + phase * 0.22) * h * 0.012;
      final peak = baseY - h * (0.10 + v * 0.09) + undulation;
      farPath.lineTo(x, peak.clamp(h * 0.53, baseY).toDouble());
    }
    farPath
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      farPath,
      Paint()..color = colorAt(0.22, energy: energy, bass: bass).withValues(alpha: 0.22),
    );

    // Build connected block-like forms. Low bands control wide blocks while
    // high bands contribute narrow rooftop spires in the same silhouette.
    const segmentCount = 36;
    final step = w / segmentCount;
    final front = Path()..moveTo(0, baseY);
    final tops = <double>[];
    for (var i = 0; i < segmentCount; i++) {
      final lowIndex = (i * math.max(1, bands.length) ~/ segmentCount)
          .clamp(0, math.max(0, bands.length - 1)).toInt();
      final highIndex = ((bands.length * 0.58) + i * math.max(1, bands.length) / segmentCount)
          .floor()
          .clamp(0, math.max(0, bands.length - 1))
          .toInt();
      final low = bands.isEmpty ? 0.0 : bandAt(lowIndex);
      final high = bands.isEmpty ? 0.0 : bandAt(highIndex);
      final widthFactor = (0.78 + (low * 0.25)).clamp(0.72, 1.0).toDouble();
      final modulation = 0.88 + 0.12 * math.sin(phase * 0.55 + i * 0.63);
      final bodyHeight = h * (0.085 + low * 0.17 * bassBoost) * intensity * modulation;
      final spireHeight = h * high * 0.12 * intensity;
      final top = (baseY - bodyHeight - spireHeight).clamp(h * 0.27, baseY).toDouble();
      tops.add(top);
      final x0 = i * step;
      final x1 = x0 + step * widthFactor;
      final shoulder = baseY - bodyHeight;
      front
        ..lineTo(x0, shoulder)
        ..lineTo(x0 + step * 0.12, shoulder)
        ..lineTo(x0 + step * 0.12, top)
        ..lineTo(x1 - step * 0.12, top)
        ..lineTo(x1 - step * 0.12, shoulder)
        ..lineTo(x1, shoulder)
        ..lineTo(x1, baseY);
    }
    front
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final cityColor = colorAt(0.46, energy: energy, bass: bass);
    canvas.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorAt(0.36, energy: energy).withValues(alpha: 0.88),
            colorAt(0.12, bass: bass).withValues(alpha: 0.62),
            const Color(0xFF050710).withValues(alpha: 0.96),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(Rect.fromLTWH(0, h * 0.25, w, h * 0.75)),
    );

    // Fine roofline tracing, softly illuminated without outlining every edge.
    final roof = Path();
    for (var i = 0; i < segmentCount; i++) {
      final x = i * step + step * 0.12;
      final right = i * step + step * 0.88;
      final y = tops[i];
      if (i == 0) roof.moveTo(x, y);
      roof
        ..lineTo(right, y)
        ..lineTo(right, math.min(baseY, y + h * 0.015));
    }
    if (config.glow) {
      canvas.drawPath(
        roof,
        Paint()
          ..color = cityColor.withValues(alpha: 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius.clamp(0.0, 18.0)),
      );
    }
    canvas.drawPath(
      roof,
      Paint()
        ..color = colorAt(0.58, energy: energy).withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Sparse lit windows: fixed count and spacing keep work predictable.
    for (var i = 0; i < segmentCount; i += 2) {
      final top = tops[i];
      final x = i * step + step * 0.29;
      final height = (baseY - top).clamp(h * 0.03, h * 0.42).toDouble();
      for (var row = 0; row < 3; row++) {
        final y = top + height * (0.36 + row * 0.20);
        if (y < baseY - 3 && ((i * 7 + row * 3) % 5 != 0)) {
          final twinkle = 0.72 + 0.28 * math.sin(phase * 0.8 + i + row);
          final windowColor = colorAt(0.68, energy: energy, bass: bass);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, math.max(1.0, step * 0.14), math.max(1.2, h * 0.009)),
              const Radius.circular(0.7),
            ),
            Paint()..color = windowColor.withValues(alpha: (0.38 * twinkle).clamp(0.0, 0.55)),
          );
        }
      }
    }

    // Horizon glow and a calm baseline anchor the scene.
    final horizonRect = Rect.fromLTWH(0, baseY - h * 0.055, w, h * 0.12);
    canvas.drawRect(
      horizonRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorAt(0.72, energy: energy, bass: bass)
                .withValues(alpha: (0.10 + energy * 0.10).clamp(0.0, 0.24)),
            Colors.transparent,
          ],
        ).createShader(horizonRect)
        ..blendMode = BlendMode.screen,
    );
    canvas.drawLine(
      Offset(0, baseY),
      Offset(w, baseY),
      Paint()
        ..color = colorAt(0.40, energy: energy).withValues(alpha: 0.26)
        ..strokeWidth = 1,
    );
  }

  double _safe(double value) => value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
