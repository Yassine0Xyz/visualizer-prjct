import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';
import 'fractal_bloom_painter.dart';

/// A night-garden Fractal Bloom variation with audio-reactive petal accents.
class FractalBloomNightGardenPainter extends VisualizerPainter {
  FractalBloomNightGardenPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    FractalBloomPainter(data, config, theme).paint(canvas, size);
    if (size.isEmpty) return;
    final center = Offset(size.width * 0.5, size.height * 0.58);
    final minDimension = math.min(size.width, size.height);
    final energy = data.energy.clamp(0.0, 1.0).toDouble();
    final bass = data.bass.clamp(0.0, 1.0).toDouble();
    final high = data.high.clamp(0.0, 1.0).toDouble();
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final petalCount = 8 + (high * 4).round();
    final bloomRadius = minDimension * (0.115 + bass * 0.035 + energy * 0.018);

    // Fine inner petals echo the main branching bloom without obscuring it.
    for (var i = 0; i < petalCount; i++) {
      final angle = 2 * math.pi * i / petalCount + phase * 0.025;
      final breathing = 1.0 + math.sin(phase * 0.18 + i * 1.7) * (0.035 + energy * 0.025);
      final tip = center + Offset(math.cos(angle), math.sin(angle)) * bloomRadius * breathing;
      final side = Offset(-math.sin(angle), math.cos(angle));
      final length = bloomRadius * (0.34 + high * 0.10);
      final width = minDimension * (0.012 + energy * 0.003);
      final base = center + Offset(math.cos(angle), math.sin(angle)) * bloomRadius * 0.30;
      final petal = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          (base.dx + tip.dx) / 2 + side.dx * width,
          (base.dy + tip.dy) / 2 + side.dy * width,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          (base.dx + tip.dx) / 2 - side.dx * width,
          (base.dy + tip.dy) / 2 - side.dy * width,
          base.dx,
          base.dy,
        )
        ..close();
      final color = colorAt(i / petalCount, energy: energy, bass: bass);
      if (config.glow) {
        canvas.drawPath(
          petal,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0 + high * 1.4
            ..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: 0.12 + energy * 0.10)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              (config.glowRadius * 0.26).clamp(0.8, 4.5).toDouble(),
            ),
        );
        canvas.drawPath(
          petal,
          Paint()
            ..shader = LinearGradient(
              colors: [
                color.withValues(alpha: 0.03 + energy * 0.03),
                color.withValues(alpha: 0.14 + high * 0.10),
              ],
            ).createShader(Rect.fromPoints(base, tip))
            ..blendMode = BlendMode.screen,
        );
      }
      canvas.drawPath(
        petal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 + high * 0.45
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.20 + energy * 0.16),
      );
      if (i % 2 == 0) {
        final seedPoint = tip - Offset(math.cos(angle), math.sin(angle)) * length * 0.35;
        canvas.drawCircle(
          seedPoint,
          minDimension * (0.002 + high * 0.0015),
          Paint()..color = Colors.white.withValues(alpha: 0.28 + high * 0.30),
        );
        if (config.glow && high > 0.24) {
          final sparkle = minDimension * (0.004 + high * 0.003);
          final sparklePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.14 + high * 0.12)
            ..strokeWidth = 0.55
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            seedPoint - Offset(sparkle, 0),
            seedPoint + Offset(sparkle, 0),
            sparklePaint,
          );
          canvas.drawLine(
            seedPoint - Offset(0, sparkle * 0.65),
            seedPoint + Offset(0, sparkle * 0.65),
            sparklePaint,
          );
        }
      }
    }

    final coreColor = colorAt(0.56 + high * 0.16, energy: energy, bass: bass);
    final core = minDimension * (0.008 + bass * 0.004);
    if (config.glow) {
      final bloomRect = Rect.fromCircle(center: center, radius: core * 4.2);
      canvas.drawCircle(
        center,
        core * 4.2,
        Paint()
          ..shader = RadialGradient(colors: [
            coreColor.withValues(alpha: 0.32 + energy * 0.16),
            coreColor.withValues(alpha: 0.12 + bass * 0.06),
            Colors.transparent,
          ], stops: const [0.0, 0.35, 1.0]).createShader(bloomRect)
          ..blendMode = BlendMode.screen,
      );
      canvas.drawCircle(
        center,
        core * 2.5,
        Paint()
          ..color = coreColor.withValues(alpha: 0.14 + energy * 0.08)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (config.glowRadius * 0.24).clamp(0.8, 4.0).toDouble(),
          ),
      );
    }
  }
}
