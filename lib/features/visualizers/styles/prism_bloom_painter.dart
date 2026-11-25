import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

class PrismBloomPainter extends VisualizerPainter {
  PrismBloomPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height);
    if (minDim <= 0) return;

    final values = data.values;
    final count = values.length;
    final energy = _unit(data.energy);
    final bass = _unit(data.bass);
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final intensity = config.intensity.isFinite
        ? config.intensity.clamp(0.0, 3.0).toDouble()
        : 1.0;
    final boost = config.bassBoost.isFinite
        ? config.bassBoost.clamp(0.0, 3.0).toDouble()
        : 1.0;
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final pulse = 1.0 + bass * boost * 0.24;
    final bloomRadius = minDim * (0.235 + bass * boost * 0.035) * pulse;
    final petals = count >= 10 ? 10 : 8;
    final rotation = math.sin(phase * 0.38) * 0.065 + phase * 0.045;
    final baseColor = colorAt(0.56, energy: energy, bass: bass);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // A quiet inner halo anchors the translucent layered petals.
    final haloRadius = bloomRadius * 1.34;
    canvas.drawCircle(
      Offset.zero,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            baseColor.withValues(alpha: 0.12 + energy * 0.08),
            colorAt(0.84, energy: energy, bass: bass).withValues(alpha: 0.025),
            Colors.transparent,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: haloRadius))
        ..blendMode = BlendMode.screen,
    );

    for (var i = 0; i < petals; i++) {
      final t = i / petals;
      final band = count == 0 ? 0.0 : _unit(values[(i * count ~/ petals) % count]);
      final neighbor = count == 0 ? 0.0 : _unit(values[((i * count ~/ petals) + 1) % count]);
      final angle = rotation + 2 * math.pi * t;
      final length = bloomRadius * (0.82 + band * 0.38 * intensity + mid * 0.06);
      final width = bloomRadius * (0.29 + band * 0.035);
      final petal = _petalPath(length, width);
      final color = colorAt(t, energy: energy, bass: bass);
      final alpha = (0.19 + energy * 0.12 + band * 0.08).clamp(0.0, 0.48).toDouble();

      canvas.save();
      canvas.rotate(angle);
      canvas.translate(0, -bloomRadius * 0.17);

      canvas.drawPath(
        petal,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.30)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.screen,
      );
      canvas.drawPath(
        petal,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorAt(t + 0.08, energy: energy).withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.36),
              baseColor.withValues(alpha: alpha * 0.52),
            ],
            stops: const [0, 0.62, 1],
          ).createShader(Rect.fromLTWH(-width, -length, width * 2, length))
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.screen,
      );

      if (config.glow) {
        canvas.drawPath(
          petal,
          Paint()
            ..color = color.withValues(alpha: (0.22 + high * 0.12).clamp(0.0, 0.38))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              config.glowRadius.isFinite ? config.glowRadius.clamp(0.0, 24.0) : 0.0,
            )
            ..blendMode = BlendMode.screen,
        );
      }
      canvas.drawPath(
        petal,
        Paint()
          ..color = color.withValues(alpha: (0.48 + high * 0.22).clamp(0.0, 0.74))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9 + high * 0.5
          ..strokeJoin = StrokeJoin.round,
      );

      // A slim refracted facet, strengthened by high-frequency energy.
      if (high > 0.03) {
        final facet = Path()
          ..moveTo(-width * 0.17, -length * 0.10)
          ..quadraticBezierTo(width * 0.48, -length * 0.51, width * 0.02, -length * 0.91);
        canvas.drawPath(
          facet,
          Paint()
            ..color = colorAt(t + 0.45, energy: energy).withValues(
              alpha: (0.10 + high * 0.42 + neighbor * 0.08).clamp(0.0, 0.52),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7 + high * 0.55
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }

    final coreRadius = bloomRadius * (0.19 + bass * 0.025);
    canvas.drawCircle(
      Offset.zero,
      coreRadius * 1.48,
      Paint()
        ..color = baseColor.withValues(alpha: 0.12 + energy * 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(2.0, minDim * 0.012))
        ..blendMode = BlendMode.screen,
    );
    canvas.drawCircle(
      Offset.zero,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            colorAt(0.34, energy: energy, bass: bass).withValues(alpha: 0.82),
            baseColor.withValues(alpha: 0.42),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: coreRadius))
        ..blendMode = BlendMode.screen,
    );
    canvas.drawCircle(
      Offset.zero,
      coreRadius * 1.18,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42 + high * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    canvas.restore();
  }

  Path _petalPath(double length, double width) {
    return Path()
      ..moveTo(0, 0)
      ..cubicTo(-width * 0.93, -length * 0.18, -width * 0.70, -length * 0.78, 0, -length)
      ..cubicTo(width * 0.70, -length * 0.78, width * 0.93, -length * 0.18, 0, 0)
      ..close();
  }

  double _unit(double value) => value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
