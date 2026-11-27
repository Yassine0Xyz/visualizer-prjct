import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';
import 'orbiting_particles_painter.dart';

/// A halo-rich Orbiting Particles variation with a few audio-driven satellites.
class OrbitingParticlesHaloPainter extends VisualizerPainter {
  OrbitingParticlesHaloPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    OrbitingParticlesPainter(data, config, theme).paint(canvas, size);
    if (size.isEmpty) return;
    final center = size.center(Offset.zero);
    final minDimension = math.min(size.width, size.height);
    final energy = data.energy.clamp(0.0, 1.0).toDouble();
    final bass = data.bass.clamp(0.0, 1.0).toDouble();
    final high = data.high.clamp(0.0, 1.0).toDouble();
    final phase = data.phase.isFinite ? data.phase : 0.0;

    // Two translucent orbital halos create a layered, jewel-like silhouette.
    for (var halo = 0; halo < 2; halo++) {
      final rx = minDimension * (0.31 + halo * 0.055);
      final ry = rx * (0.48 + high * 0.05);
      final rotation = phase * (halo == 0 ? 0.055 : -0.042) + halo * 0.8;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      final rect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
      final color = colorAt(0.30 + halo * 0.42, energy: energy, bass: bass);
      if (config.glow) {
        canvas.drawOval(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0 + halo
            ..color = color.withValues(alpha: 0.10 + energy * 0.08)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              (config.glowRadius * 0.24).clamp(0.8, 4.5).toDouble(),
            ),
        );
      }
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = color.withValues(alpha: 0.10 + energy * 0.08),
      );
      canvas.drawArc(
        rect,
        phase * 0.10 + halo * math.pi,
        math.pi * (0.22 + bass * 0.12),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: 0.28 + energy * 0.16),
      );
      canvas.restore();
    }

    // Three deterministic satellites orbit smoothly; bass subtly enlarges them.
    for (var i = 0; i < 3; i++) {
      final angle = phase * (0.11 + i * 0.018) * (i.isEven ? 1 : -1) + i * math.pi * 2 / 3;
      final radiusX = minDimension * (0.32 + i * 0.035);
      final radiusY = radiusX * (0.48 + high * 0.05);
      final rotation = phase * (i.isEven ? 0.055 : -0.042) + i * 0.8;
      final local = Offset(math.cos(angle) * radiusX, math.sin(angle) * radiusY);
      final position = center + Offset(
        local.dx * math.cos(rotation) - local.dy * math.sin(rotation),
        local.dx * math.sin(rotation) + local.dy * math.cos(rotation),
      );
      final color = colorAt(0.18 + i * 0.29 + high * 0.12, energy: energy, bass: bass);
      final radius = minDimension * (0.004 + bass * 0.002 + energy * 0.001);
      if (config.glow) {
        final bloomRect = Rect.fromCircle(center: position, radius: radius * 5.0);
        canvas.drawCircle(
          position, radius * 5.0,
          Paint()
            ..shader = RadialGradient(colors: [
              color.withValues(alpha: 0.34 + energy * 0.12),
              color.withValues(alpha: 0.12 + high * 0.08),
              Colors.transparent,
            ], stops: const [0.0, 0.36, 1.0]).createShader(bloomRect)
            ..blendMode = BlendMode.screen,
        );
      }
      canvas.drawCircle(
        position,
        radius * 1.12,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: 0.95),
            color.withValues(alpha: 0.88),
            color.withValues(alpha: 0.12),
          ], stops: const [0.0, 0.38, 1.0]).createShader(
            Rect.fromCircle(center: position, radius: radius * 1.12),
          ),
      );
      canvas.drawCircle(position, radius * 1.8, Paint()..color = color.withValues(alpha: 0.72));
      final flare = radius * (2.6 + high * 1.5);
      final flarePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16 + energy * 0.12)
        ..strokeWidth = 0.65
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(position - Offset(flare, 0), position + Offset(flare, 0), flarePaint);
    }
  }
}
