import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// A holographic arena with a measured platform and a live audio reactor.
class HoloArenaPainter extends VisualizerPainter {
  HoloArenaPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite || !size.height.isFinite || size.isEmpty) return;
    paintBackground(canvas, size);

    final minDim = math.min(size.width, size.height);
    if (minDim < 8) return;
    final sensitivity = _safe(config.sensitivity, fallback: 1).clamp(0.0, 4.0);
    final intensity = _safe(config.intensity, fallback: 1).clamp(0.0, 2.5);
    final bass =
        _unit(data.bass * sensitivity * _safe(config.bassBoost, fallback: 1));
    final mid = _unit(data.mid * sensitivity);
    final high = _unit(data.high * sensitivity);
    final energy = _unit(data.energy * sensitivity);
    final phase = data.phase.isFinite ? data.phase % (math.pi * 2) : 0.0;
    final primary = colorAt(0.62, energy: energy, bass: bass);
    final cool = colorAt(0.08 + high * 0.16, energy: energy, bass: bass);

    final cx = size.width * 0.5;
    final platformY = size.height * 0.72;
    final center = Offset(cx, size.height * 0.43);
    final platformW = math.min(size.width * 0.84, minDim * 1.18);
    final platformH = math.min(size.height * 0.34, minDim * 0.43);
    final platform = Rect.fromCenter(
      center: Offset(cx, platformY),
      width: platformW,
      height: platformH,
    );

    // Restrained perspective floor: a few converging seams and floor contours.
    final floorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = primary.withValues(alpha: 0.09 + energy * 0.06);
    for (var i = -3; i <= 3; i++) {
      final spread = i * platformW * 0.105;
      canvas.drawLine(
        Offset(cx + spread * 0.28, platformY + platformH * 0.12),
        Offset(cx + spread * 1.55, size.height * 0.99),
        floorPaint,
      );
    }
    for (var i = 0; i < 4; i++) {
      final t = (i + 1) / 4;
      final y = platformY +
          platformH * 0.12 +
          (size.height * 0.99 - platformY - platformH * 0.12) * t * t;
      canvas.drawLine(Offset(cx - platformW * 0.55, y),
          Offset(cx + platformW * 0.55, y), floorPaint);
    }

    // Floating oval deck, layered to establish depth without a busy grid.
    final deckGlow = Paint()
      ..color = primary.withValues(alpha: 0.05 + energy * 0.035)
      ..maskFilter = config.glow
          ? MaskFilter.blur(BlurStyle.normal,
              _safe(config.glowRadius, fallback: 8).clamp(1.0, 9.0))
          : null;
    canvas.drawOval(platform.inflate(minDim * 0.018), deckGlow);
    canvas.drawOval(
      platform,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withValues(alpha: 0.13 + energy * 0.04),
            const Color(0xFF071421).withValues(alpha: 0.66),
            cool.withValues(alpha: 0.10 + high * 0.04),
          ],
        ).createShader(platform),
    );
    canvas.drawOval(
      platform,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = primary.withValues(alpha: 0.48 + energy * 0.2),
    );
    final innerDeck = platform.deflate(minDim * 0.025);
    canvas.drawOval(
      innerDeck,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = cool.withValues(alpha: 0.22 + high * 0.12),
    );

    // Three calibrated arc segments serve as readable arena instrumentation.
    final dialR = minDim * (0.235 + bass * 0.016);
    canvas.drawCircle(
      center,
      dialR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(alpha: 0.10),
    );
    for (var i = 0; i < 3; i++) {
      final r = dialR * (0.94 - i * 0.14);
      final c = i == 1 ? cool : primary;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        phase * (i.isEven ? 0.08 : -0.05) + i * 2.1,
        math.pi * (0.54 + (i == 0 ? energy : high) * 0.22),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 1 ? 1.5 : 1
          ..strokeCap = StrokeCap.round
          ..color = c.withValues(alpha: 0.48 + energy * 0.22),
      );
    }

    // Evenly spaced calibration marks; longer marks at cardinal positions.
    final tickPaint = Paint()
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 48; i++) {
      final angle = i * math.pi * 2 / 48 - math.pi / 2;
      final major = i % 4 == 0;
      final inner = dialR * (major ? 1.02 : 1.045);
      final outer = dialR * (major ? 1.105 : 1.075);
      tickPaint.color = (major ? Colors.white : primary)
          .withValues(alpha: major ? 0.45 + energy * 0.12 : 0.25);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        tickPaint,
      );
    }

    // Spectrum columns sit along the front edge as a tidy arena readout.
    final bands = data.values;
    final count = math.min(32, bands.length);
    if (count > 0) {
      final width = platformW * 0.60;
      final gap = math.max(1.0, minDim * 0.006);
      final barW = (width - gap * (count - 1)) / count;
      final baseY = platformY + platformH * 0.18;
      final maxH =
          math.min(platformH * 0.42, minDim * 0.13) * (0.7 + intensity * 0.3);
      final barPaint = Paint();
      for (var i = 0; i < count; i++) {
        final value = _unit(bands[i]);
        final eased = math.sqrt(value);
        final h = maxH * (0.12 + eased * (0.45 + mid * 0.55));
        final x = cx - width / 2 + i * (barW + gap);
        final rect = Rect.fromLTWH(x, baseY - h, barW, h);
        barPaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorAt(i / math.max(1, count - 1), energy: energy, bass: bass)
                .withValues(alpha: 0.88),
            cool.withValues(alpha: 0.30),
          ],
        ).createShader(rect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(barW * 0.35)),
          barPaint,
        );
      }
      canvas.drawLine(
        Offset(cx - width / 2, baseY + minDim * 0.012),
        Offset(cx + width / 2, baseY + minDim * 0.012),
        Paint()
          ..strokeWidth = 0.7
          ..color = primary.withValues(alpha: 0.35),
      );
    }

    // Compact reactor: bass controls its pulse, treble adds a fine inner ring.
    final coreR = minDim * (0.061 + bass * 0.018 + energy * 0.006);
    final coreRect = Rect.fromCircle(center: center, radius: coreR * 1.8);
    if (config.glow) {
      canvas.drawCircle(
        center,
        coreR * 1.7,
        Paint()
          ..shader = RadialGradient(colors: [
            primary.withValues(alpha: 0.22 + energy * 0.12),
            cool.withValues(alpha: 0.10 + high * 0.07),
            Colors.transparent,
          ], stops: const [
            0,
            0.48,
            1
          ]).createShader(coreRect)
          ..blendMode = BlendMode.screen,
      );
    }
    canvas.drawCircle(
      center,
      coreR,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.94),
          primary.withValues(alpha: 0.94),
          cool.withValues(alpha: 0.40),
        ], stops: const [
          0,
          0.4,
          1
        ]).createShader(Rect.fromCircle(center: center, radius: coreR)),
    );
    canvas.drawCircle(
      center,
      coreR * (1.18 + high * 0.08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.48 + high * 0.22),
    );

    // Low-contrast scan sweep across the reactor's instrument field.
    final scanY =
        center.dy - dialR + (((phase / (math.pi * 2)) % 1 + 1) % 1) * dialR * 2;
    canvas.drawLine(
      Offset(cx - dialR * 0.72, scanY),
      Offset(cx + dialR * 0.72, scanY),
      Paint()
        ..strokeWidth = 0.65
        ..color = cool.withValues(alpha: 0.10 + energy * 0.08),
    );
  }

  double _safe(double value, {required double fallback}) =>
      value.isFinite ? value : fallback;

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
