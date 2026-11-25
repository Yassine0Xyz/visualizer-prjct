import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// A compact circular spectrogram: frequency runs outward and time runs around
/// the circumference, with the newest history frames at the leading edge.
class RadialSpectrogramPainter extends VisualizerPainter {
  RadialSpectrogramPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintBackground(canvas, size);

    final frames = data.history;
    final center = size.center(Offset.zero);
    final minDimension = math.min(size.width, size.height);
    final outerRadius = minDimension * 0.405;
    final innerRadius = minDimension * 0.105;
    if (outerRadius <= innerRadius || outerRadius <= 0) return;

    final boundedFrameCount = math.min(32, frames.length);
    if (boundedFrameCount == 0) {
      // Keep the empty state deliberate and quiet rather than showing stale data.
      final ringPaint = Paint()
        ..color = colorAt(0.52, energy: data.energy, bass: data.bass)
            .withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, innerRadius, ringPaint);
      return;
    }

    final frameStride = frames.length > boundedFrameCount
        ? (frames.length - 1) / (boundedFrameCount - 1)
        : 1.0;
    final firstFrameIndex = math.max(0, frames.length - 1 - (boundedFrameCount - 1) * frameStride).round();
    final sampledFrames = <List<double>>[];
    for (var i = 0; i < boundedFrameCount; i++) {
      final index = (firstFrameIndex + i * frameStride).round().clamp(0, frames.length - 1);
      sampledFrames.add(frames[index]);
    }

    var maxBands = 0;
    for (final frame in sampledFrames) {
      maxBands = math.max(maxBands, frame.length);
    }
    final bandCount = math.min(40, maxBands);
    if (bandCount == 0) return;

    final intensity = config.intensity.clamp(0.0, 4.0).toDouble();
    final boost = config.bassBoost.clamp(0.0, 4.0).toDouble();
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final rotation = phase * 0.18;
    final sweep = math.pi * 1.55;
    final angleStep = sweep / boundedFrameCount;
    final bandStep = (outerRadius - innerRadius) / bandCount;
    final strokeWidth = math.max(0.8, math.min(2.4, minDimension * 0.0045));
    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var frameIndex = 0; frameIndex < boundedFrameCount; frameIndex++) {
      final frame = sampledFrames[frameIndex];
      if (frame.isEmpty) continue;
      final age = (frameIndex + 1) / boundedFrameCount;
      final angle = rotation - sweep * 0.5 + (frameIndex + 0.5) * angleStep;
      final cosine = math.cos(angle);
      final sine = math.sin(angle);

      for (var bandIndex = 0; bandIndex < bandCount; bandIndex++) {
        final sourceIndex = ((bandIndex + 0.5) * frame.length / bandCount)
            .floor()
            .clamp(0, frame.length - 1);
        final raw = frame[sourceIndex];
        final value = raw.isFinite ? raw.clamp(0.0, 1.0).toDouble() : 0.0;
        if (value < 0.018) continue;

        final frequency = bandIndex / math.max(1, bandCount - 1);
        final bassWeight = (1.0 - frequency).clamp(0.0, 1.0);
        final boosted = (value * (1.0 + bassWeight * boost * 0.20) * intensity)
            .clamp(0.0, 1.0)
            .toDouble();
        final radius = innerRadius + (bandIndex + 0.5) * bandStep;
        final halfLength = math.min(
          bandStep * (0.18 + boosted * 0.42),
          minDimension * 0.012,
        );
        final p1 = center + Offset(cosine, sine) * math.max(innerRadius, radius - halfLength);
        final p2 = center + Offset(cosine, sine) * math.min(outerRadius, radius + halfLength);
        final paletteT = (0.12 + frequency * 0.76 + (1 - age) * 0.08)
            .clamp(0.0, 1.0)
            .toDouble();
        final color = colorAt(paletteT, energy: boosted, bass: data.bass);
        segmentPaint
          ..color = color.withValues(alpha: ((0.10 + boosted * 0.72) * (0.30 + age * 0.70)).clamp(0.0, 0.82))
          ..strokeWidth = strokeWidth * (0.72 + boosted * 0.55);
        canvas.drawLine(p1, p2, segmentPaint);
      }
    }

    // Fine guide rings anchor the frequency radius without competing with data.
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var ring = 1; ring <= 3; ring++) {
      final radius = innerRadius + (outerRadius - innerRadius) * ring / 4;
      guidePaint.color = colorAt(ring / 4, energy: data.energy, bass: data.bass)
          .withValues(alpha: 0.075);
      canvas.drawCircle(center, radius, guidePaint);
    }

    final coreRadius = innerRadius *
        (0.30 + data.bass.clamp(0.0, 1.0).toDouble() * boost * 0.07);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = colorAt(0.55, energy: data.energy, bass: data.bass)
            .withValues(alpha: 0.24 + data.beatPhase.abs().remainder(1.0) * 0.06),
    );
  }
}
