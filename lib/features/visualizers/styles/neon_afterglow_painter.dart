import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// A deep, restrained neon spectrum with a fine afterglow around its peaks.
class NeonAfterglowPainter extends VisualizerPainter {
  NeonAfterglowPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    final count = data.values.length;
    if (count == 0 || size.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final usableCount = math.min(count, data.previousValues.length);
    final slot = size.width / count;
    final barWidth = math.max(0.8, slot * 0.56).toDouble();
    final baseline = size.height * 0.88;
    final minDimension = math.min(size.width, size.height);
    final intensity = config.intensity.isFinite
        ? config.intensity.clamp(0.0, 2.0).toDouble()
        : 1.0;
    final maxHeight = size.height * 0.66 * intensity;
    final energy = _unit(data.energy);
    final bass = _unit(data.bass);
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final glowRadius = config.glowRadius.isFinite
        ? config.glowRadius.clamp(0.0, 24.0).toDouble()
        : 0.0;

    // A quiet spectral horizon anchors the bars without competing with them.
    final horizonColor = colorAt(0.52, energy: energy, bass: bass);
    canvas.drawLine(
      Offset(0, baseline + minDimension * 0.012),
      Offset(size.width, baseline + minDimension * 0.012),
      Paint()
        ..color = horizonColor.withValues(alpha: 0.12 + energy * 0.12)
        ..strokeWidth = math.max(0.55, minDimension * 0.0015).toDouble(),
    );

    final gap = math.max(0.35, slot * 0.12).toDouble();
    final corner = Radius.circular(barWidth * 0.42);
    for (var i = 0; i < count; i++) {
      final raw = _unit(data.values[i]);
      final previous = i < usableCount ? _unit(data.previousValues[i]) : raw;
      // Slightly favor the latest filtered sample while retaining a short visual trail.
      final value = (raw * 0.82 + previous * 0.18).clamp(0.0, 1.0).toDouble();
      final x = (i + 0.5) * slot;
      final frequency = count < 2 ? 0.5 : i / (count - 1);
      final lowWeight = (1.0 - frequency).clamp(0.0, 1.0).toDouble();
      final highWeight = frequency;
      final bandDrive =
          bass * lowWeight * 0.12 + mid * 0.07 + high * highWeight * 0.11;
      final height = math
          .max(minDimension * 0.008, maxHeight * (value + bandDrive))
          .clamp(0.0, size.height * 0.78)
          .toDouble();
      final top = baseline - height;
      final color = colorAt(frequency, energy: energy, bass: bass);
      final rect = Rect.fromLTWH(
        x - barWidth / 2,
        top,
        math.max(0.5, barWidth - gap),
        height,
      );
      final bar = RRect.fromRectAndRadius(rect, corner);

      // Keep the halo close to the silhouette; the crisp body remains dominant.
      if (config.glow && glowRadius > 0 && value > 0.055) {
        final halo = math
            .min(glowRadius * (0.20 + value * 0.16), minDimension * 0.035)
            .toDouble();
        canvas.drawRRect(
          bar,
          Paint()
            ..color = color.withValues(alpha: 0.16 + value * 0.14)
            ..maskFilter = MaskFilter.blur(
                BlurStyle.normal, halo.clamp(0.5, 5.0).toDouble()),
        );
      }

      final bodyShader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withValues(alpha: 0.55 + value * 0.22),
          color,
          Color.lerp(color, Colors.white, 0.38 + high * 0.22)!,
        ],
        stops: const [0.0, 0.72, 1.0],
      ).createShader(rect);
      canvas.drawRRect(bar, Paint()..shader = bodyShader);

      // Narrow inner glint adds glass depth without washing out neighboring bands.
      if (value > 0.12 && barWidth > 2.0) {
        final glintWidth = math.max(0.55, (barWidth - gap) * 0.12).toDouble();
        final glintRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - glintWidth / 2, top + 1, glintWidth,
              math.max(0.0, height - 2)),
          Radius.circular(glintWidth),
        );
        canvas.drawRRect(
          glintRect,
          Paint()..color = Colors.white.withValues(alpha: 0.10 + value * 0.10),
        );
      }

      if (value > 0.24) {
        final capHeight = math
            .min(math.max(1.0, minDimension * 0.004), height * 0.30)
            .toDouble();
        final capRect = Rect.fromLTWH(rect.left, top, rect.width, capHeight);
        canvas.drawRRect(
          RRect.fromRectAndRadius(capRect, corner),
          Paint()..color = Colors.white.withValues(alpha: 0.40 + value * 0.26),
        );
        if (config.glow && value > 0.58 && minDimension > 24) {
          final radius = math
              .min(minDimension * (0.006 + high * 0.004), slot * 0.20)
              .toDouble();
          canvas.drawCircle(
            Offset(x, top),
            radius,
            Paint()..color = color.withValues(alpha: 0.12 + value * 0.12),
          );
        }
      }
    }
  }

  static double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
