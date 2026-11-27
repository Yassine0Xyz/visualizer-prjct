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
    final bands = data.values;
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final beat = data.beatPhase.isFinite ? data.beatPhase : phase;
    final energy = _safe(data.energy);
    final bass = _safe(data.bass);
    final mid = _safe(data.mid);
    final high = _safe(data.high);
    final bassEnergy = _safe(data.bassEnergy);
    final highEnergy = _safe(data.highEnergy);
    final intensity = config.intensity.isFinite
        ? config.intensity.clamp(0.3, 2.5).toDouble()
        : 1.0;
    final bassBoost = config.bassBoost.isFinite
        ? config.bassBoost.clamp(0.5, 3.0).toDouble()
        : 1.0;
    final baseY = h * 0.80;

    double bandAt(int index) {
      if (bands.isEmpty) return 0.0;
      final value = _safe(bands[index.clamp(0, bands.length - 1).toInt()]);
      // The analyzer already smooths its spectrum. A small attack-biased blend
      // keeps transients legible without introducing painter-owned stale state.
      final previous = data.previousValues;
      if (previous.length <= index.clamp(0, bands.length - 1).toInt()) {
        return value;
      }
      final old = _safe(previous[index.clamp(0, bands.length - 1).toInt()]);
      return old * 0.16 + value * 0.84;
    }

    final pulse = 0.5 + 0.5 * math.sin(beat * 1.7);
    final horizonY = baseY - h * 0.012 * (bassEnergy * pulse);

    // Distant, low-contrast ridge: broad frequency sampling creates a calm
    // secondary silhouette behind the sharper foreground architecture.
    final farPath = Path()..moveTo(0, horizonY);
    const farCount = 26;
    for (var i = 0; i <= farCount; i++) {
      final x = w * i / farCount;
      final index = bands.isEmpty ? 0 : (i * bands.length ~/ farCount);
      final v = bandAt(index);
      final sway = math.sin(i * 1.47 + phase * 0.18) * h * 0.008;
      final peak = horizonY - h * (0.075 + v * 0.085) - sway;
      farPath.lineTo(x, peak.clamp(h * 0.57, horizonY).toDouble());
    }
    farPath
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      farPath,
      Paint()
        ..color = colorAt(0.25, energy: energy, bass: bass)
            .withValues(alpha: 0.18 + mid * 0.035),
    );

    // A restrained atmospheric band sets the horizon apart from the buildings.
    final hazeRect = Rect.fromLTWH(0, horizonY - h * 0.09, w, h * 0.20);
    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colorAt(0.70, energy: energy, bass: bass)
                .withValues(alpha: 0.055 + bassEnergy * 0.06),
            Colors.transparent,
          ],
        ).createShader(hazeRect)
        ..blendMode = BlendMode.screen,
    );

    const segmentCount = 36;
    final step = w / segmentCount;
    final tops = List<double>.filled(segmentCount, baseY);
    final front = Path()..moveTo(0, baseY);
    final center = (segmentCount - 1) * 0.5;
    for (var i = 0; i < segmentCount; i++) {
      final lowIndex = bands.isEmpty ? 0 : i * bands.length ~/ segmentCount;
      final trebleStart = (bands.length * 0.55).floor();
      final highIndex = bands.isEmpty
          ? 0
          : (trebleStart + i * bands.length ~/ segmentCount)
              .clamp(0, bands.length - 1)
              .toInt();
      final low = bandAt(lowIndex);
      final treble = bandAt(highIndex);
      final centralEmphasis = math.max(0.0, 1.0 - (i - center).abs() / 15.0);
      final bodyHeight =
          h * (0.072 + low * 0.12 + bassEnergy * 0.045) * bassBoost * intensity;
      final spireHeight = h *
          (treble * 0.082 + highEnergy * 0.025) *
          intensity *
          (0.72 + centralEmphasis * 0.28);
      final modulation = 0.97 + 0.03 * math.sin(phase * 0.42 + i * 0.51);
      final top = (baseY - (bodyHeight + spireHeight) * modulation)
          .clamp(h * 0.25, baseY - h * 0.035)
          .toDouble();
      tops[i] = top;
      final shoulder = baseY - bodyHeight * modulation;
      final x0 = i * step;
      final inset = math.min(step * 0.12, w * 0.004);
      final x1 = x0 + step * (0.84 + low * 0.08);
      front
        ..lineTo(x0, shoulder)
        ..lineTo(x0 + inset, shoulder)
        ..lineTo(x0 + inset, top)
        ..lineTo(x1 - inset, top)
        ..lineTo(x1 - inset, shoulder)
        ..lineTo(x1, shoulder)
        ..lineTo(x1, baseY);
    }
    front
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final cityColor = colorAt(0.46, energy: energy, bass: bass);
    final gradientRect = Rect.fromLTWH(0, h * 0.24, w, h * 0.76);
    canvas.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorAt(0.42, energy: energy, bass: high).withValues(alpha: 0.91),
            colorAt(0.20, energy: mid, bass: bass).withValues(alpha: 0.78),
            const Color(0xFF050710).withValues(alpha: 0.99),
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(gradientRect),
    );

    // Discontinuous roof highlights preserve the block rhythm and avoid a
    // bright outline that would flatten the silhouette.
    final roof = Path();
    for (var i = 0; i < segmentCount; i++) {
      final x = i * step + math.min(step * 0.12, w * 0.004);
      final right = i * step +
          step *
              (0.84 +
                  bandAt(
                        bands.isEmpty ? 0 : i * bands.length ~/ segmentCount,
                      ) *
                      0.08) -
          math.min(step * 0.12, w * 0.004);
      if (i == 0 || tops[i] < tops[i - 1] - h * 0.006) {
        roof.moveTo(x, tops[i]);
      }
      roof.lineTo(right, tops[i]);
    }
    if (config.glow && config.glowRadius > 0 && w > 2 && h > 2) {
      canvas.drawPath(
        roof,
        Paint()
          ..color = cityColor.withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            config.glowRadius.clamp(0.0, 18.0),
          ),
      );
    }
    canvas.drawPath(
      roof,
      Paint()
        ..color = colorAt(0.59, energy: high, bass: bass)
            .withValues(alpha: 0.30 + highEnergy * 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.65, math.min(1.0, w / 500)),
    );

    // Sparse windows sit in the lower facade, leaving the skyline profile clear.
    if (w >= 18 && h >= 28) {
      final windowPaint = Paint();
      for (var i = 1; i < segmentCount; i += 3) {
        final top = tops[i];
        final x = i * step + step * 0.29;
        final facadeHeight = baseY - top;
        final rows = facadeHeight > h * 0.20 ? 3 : 2;
        for (var row = 0; row < rows; row++) {
          final y = top + facadeHeight * (0.48 + row * 0.16);
          if (y >= baseY - h * 0.025) continue;
          final twinkle = 0.78 + 0.22 * math.sin(phase * 0.72 + i * 0.8 + row);
          windowPaint.color = colorAt(0.72, energy: high, bass: bass)
              .withValues(alpha: (0.24 + energy * 0.13) * twinkle);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                x,
                y,
                math.max(0.8, math.min(step * 0.16, w * 0.012)),
                math.max(1.0, math.min(h * 0.008, 2.5)),
              ),
              const Radius.circular(0.65),
            ),
            windowPaint,
          );
        }
      }
    }

    // Narrow, subdued horizon accent; bass pulses alter its luminance rather
    // than washing over the architectural details.
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(w, horizonY),
      Paint()
        ..color = colorAt(0.43, energy: energy, bass: bass)
            .withValues(alpha: 0.18 + bassEnergy * (0.10 + pulse * 0.08))
        ..strokeWidth = math.max(0.7, math.min(1.1, h / 360)),
    );
  }

  double _safe(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
