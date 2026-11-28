import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// A dramatic, audio-reactive tear through a layered interstellar nebula.
class NebulaRiftPainter extends VisualizerPainter {
  NebulaRiftPainter(super.data, super.config, super.theme);

  double _safe(double value, [double fallback = 0]) =>
      value.isFinite ? value : fallback;

  double _unit(double value) => _safe(value).clamp(0.0, 1.0).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }
    paintBackground(canvas, size);

    final width = size.width;
    final height = size.height;
    final minDim = math.min(width, height);
    final center = Offset(width * 0.5, height * 0.51);
    final energy = _unit(data.energy);
    final bass = (_unit(data.bass) *
            _safe(config.bassBoost, 1).clamp(0.5, 3.0).toDouble())
        .clamp(0.0, 1.0)
        .toDouble();
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final intensity = _safe(config.intensity, 1).clamp(0.3, 2.5).toDouble();
    final phase = _safe(data.phase);

    // Use the already-smoothed spectrum as a bounded contribution to both
    // ends of the palette and to the fine structure around the tear.
    final bands = data.values;
    var lowSpectrum = bass;
    var trebleSpectrum = high;
    if (bands.isNotEmpty) {
      final edgeCount = math.min(4, bands.length);
      var lowSum = 0.0;
      var highSum = 0.0;
      for (var i = 0; i < edgeCount; i++) {
        lowSum += _unit(bands[i]);
        highSum += _unit(bands[bands.length - 1 - i]);
      }
      lowSpectrum = (bass * 0.62 + lowSum / edgeCount * 0.38).clamp(0.0, 1.0);
      trebleSpectrum =
          (high * 0.62 + highSum / edgeCount * 0.38).clamp(0.0, 1.0);
    }

    final isSmall = minDim < 180;
    final halfSpan = math.min(height * 0.39, width * (isSmall ? 0.34 : 0.38));
    final halfWidth = math.min(width * 0.21, minDim * 0.22) *
        (0.78 + lowSpectrum * 0.22) *
        (0.92 + energy * 0.08);
    final top = center.dy - halfSpan;
    final bottom = center.dy + halfSpan;
    final pulse = math.sin(phase * 0.13);
    final drift = math.sin(phase * 0.055) * minDim * 0.014;
    final coreX = center.dx + drift;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Broad, restrained nebula veils: asymmetric layered ribbons rather than
    // isolated light spots, all converging toward the central rupture.
    for (var layer = 0; layer < 4; layer++) {
      final side = layer.isEven ? -1.0 : 1.0;
      final t = layer / 3;
      final reach = halfWidth * (1.55 + t * 0.85);
      final skew = math.sin(phase * 0.035 + layer * 1.8) * minDim * 0.022;
      final path = Path()
        ..moveTo(coreX + side * halfWidth * 0.28, top + halfSpan * 0.13)
        ..cubicTo(
          coreX + side * (reach * 0.72) + skew,
          top + halfSpan * 0.10,
          center.dx - side * reach * 1.20 + skew,
          center.dy - halfSpan * 0.48,
          center.dx - side * reach * 0.88,
          center.dy - halfSpan * 0.10,
        )
        ..cubicTo(
          center.dx - side * reach * 0.52,
          center.dy + halfSpan * (0.12 + mid * 0.06),
          coreX + side * reach * 1.08 - skew,
          bottom - halfSpan * 0.15,
          coreX - side * halfWidth * 0.34,
          bottom - halfSpan * 0.07,
        );
      final color = colorAt(0.12 + t * 0.72 + (side > 0 ? 0.08 : 0),
          energy: energy, bass: bass);
      final widthStroke = minDim *
          (0.095 - t * 0.012) *
          (0.72 + lowSpectrum * 0.28) *
          intensity.clamp(0.65, 1.3);
      final veil = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = widthStroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.035 + energy * 0.025)
        ..blendMode = BlendMode.screen;
      canvas.drawPath(path, veil);
      final thread = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, minDim * (0.003 + high * 0.002))
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.13 + mid * 0.10 + energy * 0.07)
        ..blendMode = BlendMode.screen;
      canvas.drawPath(path, thread);
    }

    // Dark, tapered interior establishes a single unmistakable focal point.
    final voidPath = Path()
      ..moveTo(coreX + drift * 0.2, top)
      ..cubicTo(
          coreX - halfWidth * 0.78,
          top + halfSpan * 0.36,
          coreX + halfWidth * 0.62,
          center.dy - halfSpan * 0.13,
          coreX,
          center.dy)
      ..cubicTo(
          coreX - halfWidth * 0.63,
          center.dy + halfSpan * 0.16,
          coreX + halfWidth * 0.78,
          bottom - halfSpan * 0.32,
          coreX - drift * 0.2,
          bottom)
      ..cubicTo(
          coreX - halfWidth * 0.18,
          bottom - halfSpan * 0.18,
          coreX + halfWidth * 0.20,
          center.dy + halfSpan * 0.13,
          coreX + halfWidth * 0.04,
          center.dy)
      ..cubicTo(
          coreX + halfWidth * 0.22,
          center.dy - halfSpan * 0.15,
          coreX - halfWidth * 0.18,
          top + halfSpan * 0.16,
          coreX + drift * 0.2,
          top)
      ..close();
    canvas.drawPath(
      voidPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF080914),
            Color(0xFF010207),
            Color(0xFF090817)
          ],
        ).createShader(
            Rect.fromLTWH(coreX - halfWidth, top, halfWidth * 2, halfSpan * 2)),
    );

    // Opposed edge ribbons use distinct palettes, with a narrow luminous rim
    // and a controlled soft underglow when glow is enabled.
    for (var side = -1; side <= 1; side += 2) {
      final edge = Path()
        ..moveTo(coreX + side * halfWidth * 0.18, top + halfSpan * 0.02)
        ..cubicTo(
            coreX - side * halfWidth * 0.66,
            top + halfSpan * 0.34,
            coreX + side * halfWidth * 0.58,
            center.dy - halfSpan * 0.14,
            coreX + side * halfWidth * 0.06,
            center.dy)
        ..cubicTo(
            coreX - side * halfWidth * 0.52,
            center.dy + halfSpan * 0.18,
            coreX + side * halfWidth * 0.67,
            bottom - halfSpan * 0.31,
            coreX - side * halfWidth * 0.16,
            bottom - halfSpan * 0.02);
      final color = colorAt(side < 0 ? 0.10 + trebleSpectrum * 0.07 : 0.72,
          energy: energy, bass: bass);
      if (config.glow && config.glowRadius > 0 && !isSmall) {
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(3, minDim * (0.025 + bass * 0.012))
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.10 + energy * 0.08)
          ..blendMode = BlendMode.screen
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (_safe(config.glowRadius).clamp(0.0, 32.0) * 0.13)
                .clamp(0.7, 3.2)
                .toDouble(),
          );
        canvas.drawPath(edge, glow);
      }
      final rim = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, minDim * (0.006 + high * 0.003))
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.52 + high * 0.18),
            colorAt(side < 0 ? 0.86 : 0.28, energy: energy, bass: bass)
                .withValues(alpha: 0.76 + energy * 0.16),
            color.withValues(alpha: 0.42 + trebleSpectrum * 0.25),
          ],
        ).createShader(Rect.fromLTRB(0, top, width, bottom))
        ..blendMode = BlendMode.screen;
      canvas.drawPath(edge, rim);

      // Fine striations along the lip catch high-frequency detail.
      final striation = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, minDim * 0.0016)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.14 + high * 0.22);
      final glint = Path()
        ..moveTo(coreX + side * halfWidth * 0.31, center.dy - halfSpan * 0.48)
        ..quadraticBezierTo(
            coreX - side * halfWidth * 0.48,
            center.dy - halfSpan * 0.17,
            coreX + side * halfWidth * 0.17,
            center.dy - halfSpan * 0.02);
      canvas.drawPath(glint, striation);
    }

    // A short central event horizon, darkest at the center and edged in color.
    final horizonRadius = math.max(2.0, minDim * (0.025 + bass * 0.011));
    final horizonRect = Rect.fromCenter(
        center: Offset(coreX, center.dy),
        width: halfWidth * 1.18,
        height: horizonRadius * 2);
    canvas.drawOval(
      horizonRect,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF000105),
          const Color(0xFF050611),
          colorAt(0.74, energy: energy, bass: bass).withValues(alpha: 0.70),
        ], stops: const [
          0,
          0.73,
          1
        ]).createShader(horizonRect),
    );
    final horizonLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, minDim * (0.0018 + high * 0.001))
      ..color = Colors.white.withValues(alpha: 0.20 + high * 0.24);
    canvas.drawLine(Offset(coreX - halfWidth * 0.48, center.dy),
        Offset(coreX + halfWidth * 0.48, center.dy), horizonLine);

    // Sparse shards point toward the tear; their motion is deterministic and
    // restrained, with treble controlling their size and brightness.
    const shards = 12;
    for (var i = 0; i < shards; i++) {
      final seed = i + 1;
      final side = i.isEven ? -1.0 : 1.0;
      final yUnit = ((seed * 37) % 97) / 96.0;
      final y = center.dy + (yUnit - 0.5) * halfSpan * 2.15;
      final sideDistance = 0.12 + ((seed * 23) % 79) / 100.0;
      final x = coreX + side * (halfWidth * (1.15 + sideDistance * 1.8));
      final twinkle =
          0.55 + 0.45 * math.sin(phase * 0.2 + i * 2.1 + pulse).abs();
      final length = minDim * (0.008 + high * 0.009) * twinkle;
      final point = Offset(x, y);
      final end = Offset(
          x - side * length, y + math.sin(phase * 0.08 + i) * length * 0.35);
      canvas.drawLine(
        point,
        end,
        Paint()
          ..strokeWidth = math.max(0.7, minDim * 0.0015)
          ..strokeCap = StrokeCap.round
          ..color = colorAt(i.isEven ? 0.78 : 0.16, energy: energy, bass: bass)
              .withValues(alpha: 0.28 + twinkle * 0.30 + trebleSpectrum * 0.18),
      );
      if (i % 3 == 0) {
        canvas.drawCircle(
            point,
            math.max(0.8, minDim * (0.002 + high * 0.001)),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.30 + high * 0.28));
      }
    }

    // Two narrow plasma wisps extend from the aperture, pulsing with bass.
    final jetLength = minDim *
        (0.035 + bass * 0.055 + energy * 0.018) *
        intensity.clamp(0.65, 1.3);
    for (var side = -1; side <= 1; side += 2) {
      final start = Offset(coreX, center.dy + side * horizonRadius * 0.75);
      final end = Offset(coreX + math.sin(phase * 0.07 + side) * minDim * 0.012,
          start.dy + side * jetLength);
      final jet = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(coreX + math.sin(phase * 0.04) * minDim * 0.018,
            (start.dy + end.dy) * 0.52, end.dx, end.dy);
      canvas.drawPath(
        jet,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, minDim * (0.002 + high * 0.0018))
          ..strokeCap = StrokeCap.round
          ..color = colorAt(side < 0 ? 0.82 : 0.18, energy: energy, bass: bass)
              .withValues(alpha: 0.38 + energy * 0.20 + high * 0.12)
          ..blendMode = BlendMode.screen,
      );
    }
    canvas.restore();
  }
}
