import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';
import '../visualizer_config.dart';

/// Head-to-head energy arena with stereo-channel and bass-versus-treble modes.
class DuelPainter extends VisualizerPainter {
  DuelPainter(super.data, super.config, super.theme);

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(canvas, size);
    if (size.isEmpty) return;

    final minSide = math.min(size.width, size.height);
    final center = Offset(size.width * 0.5, size.height * 0.51);
    final frequencyMode = config.duelMode == DuelMode.bassVsTreble;
    final leftEnergy = (frequencyMode ? data.bass : data.duelLeftEnergy)
        .clamp(0.0, 1.0)
        .toDouble();
    final rightEnergy = (frequencyMode ? data.high : data.duelRightEnergy)
        .clamp(0.0, 1.0)
        .toDouble();
    final leftLabel = frequencyMode ? 'BASS' : 'LEFT CHANNEL';
    final rightLabel = frequencyMode ? 'TREBLE' : 'RIGHT CHANNEL';
    final balance = (leftEnergy - rightEnergy).clamp(-1.0, 1.0).toDouble();
    final leftColor = colorAt(0.12, energy: leftEnergy, bass: data.bass);
    final rightColor = colorAt(0.84, energy: rightEnergy, bass: data.bass);

    final arenaRect = Rect.fromCenter(
      center: center,
      width: math.min(size.width * 0.92, minSide * 1.72),
      height: minSide * 0.78,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(arenaRect, Radius.circular(minSide * 0.12)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.035)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(center.dx, arenaRect.top + minSide * 0.09),
      Offset(center.dx, arenaRect.bottom - minSide * 0.09),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1,
    );

    // The winning side advances while its opponent is pushed back by the same
    // amount. Equal source strength always yields a perfectly mirrored arena.
    final advance = balance * minSide * 0.075;
    final baseOffset = math.min(minSide * 0.245, size.width * 0.255);
    final leftCenter = Offset(center.dx - baseOffset + advance, center.dy);
    final rightCenter = Offset(center.dx + baseOffset + advance, center.dy);
    final beatPulse = math.sin(data.beatPhase).abs();
    final leftRadius = minSide * (0.073 + leftEnergy * 0.070 + beatPulse * leftEnergy * 0.012);
    final rightRadius = minSide * (0.073 + rightEnergy * 0.070 + beatPulse * rightEnergy * 0.012);

    _drawEnergyTrail(canvas, center, leftCenter, leftRadius, leftColor, leftEnergy, true, minSide);
    _drawEnergyTrail(canvas, center, rightCenter, rightRadius, rightColor, rightEnergy, false, minSide);
    _drawCore(canvas, leftCenter, leftRadius, leftEnergy, leftColor, data.phase, true);
    _drawCore(canvas, rightCenter, rightRadius, rightEnergy, rightColor, -data.phase * 0.91, false);

    final clash = ((leftEnergy + rightEnergy) * 0.5).clamp(0.0, 1.0).toDouble();
    final clashPoint = Offset(center.dx + balance * minSide * 0.035, center.dy);
    if (clash > 0.015) {
      final blendColor = Color.lerp(leftColor, rightColor, 0.5)!;
      _drawImpactVfx(canvas, clashPoint, minSide, clash, beatPulse, blendColor);
      _drawSparks(canvas, clashPoint, minSide, clash, balance, leftColor, rightColor);
    }

    _drawCaption(
      canvas,
      Offset(arenaRect.left + minSide * 0.08, arenaRect.top + minSide * 0.07),
      leftLabel,
      leftColor,
      leftEnergy,
      true,
    );
    _drawCaption(
      canvas,
      Offset(arenaRect.right - minSide * 0.08, arenaRect.top + minSide * 0.07),
      rightLabel,
      rightColor,
      rightEnergy,
      false,
    );
    _drawFairnessNote(
      canvas,
      Offset(center.dx, arenaRect.bottom - minSide * 0.055),
      size.width,
      frequencyMode
          ? 'BASS VS TREBLE  ·  SHARED SCALE'
          : 'STEREO ENERGY  ·  SHARED SCALE',
    );
  }

  void _drawEnergyTrail(
    Canvas canvas,
    Offset center,
    Offset core,
    double radius,
    Color color,
    double energy,
    bool isLeft,
    double minSide,
  ) {
    if (energy < 0.015) return;
    final direction = isLeft ? 1.0 : -1.0;
    final start = Offset(core.dx + direction * radius * 0.82, core.dy);
    final end = Offset(center.dx + (isLeft ? -1 : 1) * minSide * 0.025, center.dy);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + direction * minSide * 0.10,
        start.dy - minSide * (0.09 + energy * 0.04),
        end.dx - direction * minSide * 0.08,
        end.dy + minSide * (0.09 + energy * 0.04),
        end.dx,
        end.dy,
      );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0.02),
            color.withValues(alpha: 0.10 + energy * 0.20),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromPoints(start, end).inflate(minSide * 0.14))
        ..style = PaintingStyle.stroke
        ..strokeWidth = minSide * (0.008 + energy * 0.012)
        ..strokeCap = StrokeCap.round
        ..maskFilter = config.glow
            ? MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.65)
            : null,
    );
  }

  void _drawCore(
    Canvas canvas,
    Offset center,
    double radius,
    double energy,
    Color color,
    double phase,
    bool clockwise,
  ) {
    final intensity = (0.18 + energy * 0.82).clamp(0.0, 1.0).toDouble();
    canvas.drawCircle(
      center,
      radius * (1.48 + energy * 0.12),
      Paint()
        ..color = color.withValues(alpha: 0.07 + energy * 0.13)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          config.glowRadius * (0.8 + energy * 0.35),
        ),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.30, -0.34),
          radius: 0.98,
          colors: [
            Colors.white.withValues(alpha: 0.88),
            Color.lerp(color, Colors.white, 0.28)!.withValues(alpha: 0.98),
            color.withValues(alpha: 0.98),
            Color.lerp(color, Colors.black, 0.74)!,
          ],
          stops: const [0.0, 0.14, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * 0.78,
      Paint()
        ..color = color.withValues(alpha: 0.20 + intensity * 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.24),
    );

    // Matched orbit rings: only rotation direction differs between fighters.
    final direction = clockwise ? 1.0 : -1.0;
    for (var ring = 0; ring < 2; ring++) {
      final rect = Rect.fromCenter(
        center: center,
        width: radius * (2.28 + ring * 0.30),
        height: radius * (1.48 + ring * 0.27),
      );
      final start = phase * direction + ring * math.pi;
      canvas.drawArc(
        rect,
        start,
        math.pi * (1.10 + energy * 0.45),
        false,
        Paint()
          ..color = color.withValues(alpha: 0.36 + energy * 0.42 - ring * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, radius * (0.035 - ring * 0.008))
          ..strokeCap = StrokeCap.round
          ..maskFilter = config.glow
              ? MaskFilter.blur(BlurStyle.normal, config.glowRadius * 0.32)
              : null,
      );
    }
    canvas.drawCircle(
      Offset(center.dx - radius * 0.28, center.dy - radius * 0.30),
      radius * 0.075,
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
  }

  void _drawSparks(
    Canvas canvas,
    Offset center,
    double minSide,
    double clash,
    double balance,
    Color leftColor,
    Color rightColor,
  ) {
    // Deterministic, phase-driven sparks keep the effect lively without
    // allocating particle state or letting either fighter gain an advantage.
    final count = 18 + (clash * 18).round();
    for (var i = 0; i < count; i++) {
      final seed = i * 2.399963229728653 +
          data.phase * (i.isEven ? 1.0 : -0.82) +
          balance * 0.5;
      final direction = Offset(math.cos(seed), math.sin(seed) * 0.78);
      final travel = minSide * (0.040 + ((i * 37) % 11) / 160 + clash * 0.045);
      final flicker = 0.72 + 0.28 * math.sin(data.phase * 3.2 + i * 1.7).abs();
      final point = Offset(
        center.dx + direction.dx * travel,
        center.dy + direction.dy * travel,
      );
      final color = i.isEven ? leftColor : rightColor;
      final tail = Offset(
        point.dx - direction.dx * travel * (0.12 + clash * 0.10),
        point.dy - direction.dy * travel * (0.12 + clash * 0.10),
      );
      final sparkPaint = Paint()
        ..color = Color.lerp(color, Colors.white, 0.38)!
            .withValues(alpha: (0.48 + clash * 0.48) * flicker)
        ..strokeWidth = minSide * (0.0022 + clash * 0.0018)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(tail, point, sparkPaint);
      canvas.drawCircle(
        point,
        minSide * (0.0022 + clash * 0.0022) * flicker,
        Paint()
          ..color = Colors.white.withValues(alpha: (0.55 + clash * 0.4) * flicker)
          ..maskFilter = config.glow
              ? MaskFilter.blur(BlurStyle.normal, minSide * 0.004)
              : null,
      );
    }
  }

  void _drawImpactVfx(
    Canvas canvas,
    Offset center,
    double minSide,
    double clash,
    double beatPulse,
    Color blendColor,
  ) {
    final pulse = (math.sin(data.phase * 2.4).abs() * 0.35 + beatPulse * 0.65);
    final flashRadius = minSide * (0.013 + clash * 0.025) * (0.88 + pulse * 0.35);
    canvas.drawCircle(
      center,
      flashRadius * (2.5 + pulse * 0.8),
      Paint()
        ..color = blendColor.withValues(alpha: 0.16 + clash * 0.20 + pulse * 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, minSide * 0.038),
    );
    canvas.drawCircle(
      center,
      flashRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.98),
            Color.lerp(blendColor, Colors.white, 0.38)!
                .withValues(alpha: 0.94),
            blendColor.withValues(alpha: 0.72),
            Colors.transparent,
          ],
          stops: const [0.0, 0.18, 0.52, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: flashRadius)),
    );

    // Paired elliptical shockwaves expand and fade from each impact.
    for (var ring = 0; ring < 2; ring++) {
      final ringPhase = (data.phase * 0.72 + ring * 0.5) % 1.0;
      final ringRect = Rect.fromCenter(
        center: center,
        width: minSide * (0.055 + ringPhase * 0.20),
        height: minSide * (0.030 + ringPhase * 0.105),
      );
      final alpha = (1.0 - ringPhase) * (0.30 + clash * 0.48);
      canvas.drawOval(
        ringRect,
        Paint()
          ..color = Color.lerp(blendColor, Colors.white, 0.32)!
              .withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = minSide * (0.002 + clash * 0.002)
          ..maskFilter = config.glow
              ? MaskFilter.blur(BlurStyle.normal, minSide * 0.006)
              : null,
      );
    }

    // Short jagged energy arcs connect the two approaching cores at impact.
    for (var arc = 0; arc < 4; arc++) {
      final angle = arc * math.pi / 2 + data.phase * (arc.isEven ? 0.7 : -0.55);
      final length = minSide * (0.045 + clash * 0.045);
      final dx = math.cos(angle);
      final dy = math.sin(angle) * 0.72;
      final path = Path()..moveTo(center.dx, center.dy);
      for (var segment = 1; segment <= 4; segment++) {
        final t = segment / 4;
        final jitter = segment == 4
            ? 0.0
            : math.sin(data.phase * 4 + arc * 2.1 + segment * 2.7) * length * 0.18;
        path.lineTo(
          center.dx + dx * length * t - dy * jitter,
          center.dy + dy * length * t + dx * jitter,
        );
      }
      final arcColor = arc.isEven ? Colors.white : blendColor;
      canvas.drawPath(
        path,
        Paint()
          ..color = arcColor.withValues(alpha: 0.45 + clash * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = minSide * (0.0018 + clash * 0.0015)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = config.glow
              ? MaskFilter.blur(BlurStyle.normal, minSide * 0.004)
              : null,
      );
    }
  }

  void _drawCaption(
    Canvas canvas,
    Offset position,
    String label,
    Color color,
    double strength,
    bool alignLeft,
  ) {
    final text = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: TextStyle(
              color: color.withValues(alpha: 0.72),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          TextSpan(
            text: '${(strength * 100).round()}%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: alignLeft ? TextAlign.left : TextAlign.right,
    )..layout();
    text.paint(
      canvas,
      Offset(alignLeft ? position.dx : position.dx - text.width, position.dy),
    );
  }

  void _drawFairnessNote(
    Canvas canvas,
    Offset center,
    double width,
    String label,
  ) {
    final note = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.28),
          fontSize: 8,
          letterSpacing: 1.25,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width * 0.72);
    note.paint(canvas, Offset(center.dx - note.width / 2, center.dy));
  }
}
