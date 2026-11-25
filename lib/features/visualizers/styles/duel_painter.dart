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
    final leadStrength = ((balance.abs() - 0.035) / 0.38)
        .clamp(0.0, 1.0)
        .toDouble();

    _drawEnergyTrail(canvas, center, leftCenter, leftRadius, leftColor, leftEnergy, true, minSide);
    _drawEnergyTrail(canvas, center, rightCenter, rightRadius, rightColor, rightEnergy, false, minSide);
    if (balance > 0.035) {
      _drawVictoryAura(
        canvas,
        leftCenter,
        leftRadius,
        leftColor,
        leftEnergy,
        leadStrength,
      );
    } else if (balance < -0.035) {
      _drawVictoryAura(
        canvas,
        rightCenter,
        rightRadius,
        rightColor,
        rightEnergy,
        leadStrength,
      );
    }
    _drawCore(canvas, leftCenter, leftRadius, leftEnergy, leftColor, data.phase, true);
    _drawCore(canvas, rightCenter, rightRadius, rightEnergy, rightColor, -data.phase * 0.91, false);

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

  void _drawVictoryAura(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double energy,
    double strength,
  ) {
    if (strength <= 0.01) return;
    final beatPulse = math.sin(data.beatPhase).abs();
    final pulse = 0.62 + 0.20 * math.sin(data.phase * 1.7).abs() + beatPulse * 0.18;
    canvas.drawCircle(
      center,
      radius * (1.48 + strength * 0.16 + beatPulse * 0.025),
      Paint()
        ..color = color.withValues(alpha: 0.10 * strength * pulse)
        ..maskFilter = config.glow
            ? MaskFilter.blur(BlurStyle.normal, radius * 0.50)
            : null,
    );

    const tongues = 14;
    final maxLength = radius * (0.32 + energy * 0.38) * (0.78 + strength * 0.22);
    final maxHalfWidth = radius * (0.12 + energy * 0.045);
    final flameShaderRect = Rect.fromLTRB(
      -maxHalfWidth * 1.6,
      radius * 0.55,
      maxHalfWidth * 1.6,
      radius + maxLength,
    );
    final flamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withValues(alpha: 0.05 * strength),
          color.withValues(alpha: 0.36 * strength * pulse),
          color.withValues(alpha: 0.24 * strength),
          color.withValues(alpha: 0.015 * strength),
        ],
        stops: const [0.0, 0.25, 0.62, 1.0],
      ).createShader(flameShaderRect)
      ..blendMode = BlendMode.plus;
    final hotCorePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color.lerp(color, Colors.white, 0.12)!
              .withValues(alpha: 0.24 * strength),
          Color.lerp(color, Colors.white, 0.42)!
              .withValues(alpha: 0.27 * strength * pulse),
          color.withValues(alpha: 0.01 * strength),
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(flameShaderRect)
      ..blendMode = BlendMode.plus;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var i = 0; i < tongues; i++) {
      final flicker = 0.52 +
          0.48 * math.sin(data.phase * (2.4 + (i % 4) * 0.31) + i * 2.17).abs();
      final length = maxLength * flicker * (i.isEven ? 1.0 : 0.76);
      final halfWidth = maxHalfWidth *
          (0.70 + 0.30 * math.sin(data.phase * 1.9 + i * 1.41).abs());
      final angle = (math.pi * 2 * i / tongues) + data.phase * 0.12;
      final lean = math.sin(data.phase * 2.1 + i * 2.7) * halfWidth * 0.34;
      final path = Path()
        ..moveTo(-halfWidth * 0.48, radius * 0.66)
        ..cubicTo(
          -halfWidth * 1.05,
          radius * 0.90,
          -halfWidth * 0.60 + lean,
          radius + length * 0.48,
          lean * 0.48,
          radius + length,
        )
        ..cubicTo(
          halfWidth * 0.24 + lean,
          radius + length * 0.52,
          halfWidth * 1.02,
          radius * 0.88,
          halfWidth * 0.48,
          radius * 0.66,
        )
        ..cubicTo(
          halfWidth * 0.13,
          radius * 0.78,
          -halfWidth * 0.22,
          radius * 0.77,
          -halfWidth * 0.48,
          radius * 0.66,
        )
        ..close();
      canvas.save();
      canvas.rotate(angle);
      canvas.drawPath(path, flamePaint);
      canvas.save();
      canvas.scale(0.44, 0.70);
      canvas.drawPath(path, hotCorePaint);
      canvas.restore();
      canvas.restore();
    }
    canvas.restore();
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
