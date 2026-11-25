import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../base/visualizer_painter.dart';

/// Cinematic Bass-vs-Treble duel rendered entirely with bounded vector paths.
/// It owns no timers or animation controllers; motion follows VisualizerData.phase.
class AnimeFightersPainter extends VisualizerPainter {
  AnimeFightersPainter(super.data, super.config, super.theme);

  static const _blue = Color(0xFF35B9FF);
  static const _purple = Color(0xFFB56CFF);
  static const _silhouette = Color(0xFF080C18);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final minSide = math.min(w, h);
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final bass = _unit(data.bass);
    final treble = _unit(data.high);
    final bassPeak = _unit(data.bassEnergy);
    final treblePeak = _unit(data.highEnergy);
    final clash = _unit(data.fighterClash);
    final fighterScale = minSide * 0.335;
    final groundY = h * 0.70;
    final center = Offset(w * 0.5, groundY);

    _drawBackdrop(canvas, size, center, minSide, phase, bass, treble, clash);
    _drawFloor(canvas, size, center, minSide, phase, clash);

    // Each stance breathes gently at idle and gains a distinct audio-driven
    // response: weighty bass shoulder/stance motion vs precise treble motion.
    final bassIdle = math.sin(phase * 1.65) * 0.012;
    final trebleIdle = math.sin(phase * 2.13 + 1.2) * 0.010;
    final bassDrive = (bass * 0.040 + bassPeak * 0.020).clamp(0.0, 0.055).toDouble();
    final trebleDrive = (treble * 0.024 + treblePeak * 0.025).clamp(0.0, 0.050).toDouble();
    final advance = clash * 0.145;
    final separation = w * 0.257;
    final blueFoot = Offset(w * 0.5 - separation + fighterScale * advance,
        groundY + fighterScale * (bassIdle - bassDrive * 0.25));
    final purpleFoot = Offset(w * 0.5 + separation - fighterScale * advance,
        groundY + fighterScale * (trebleIdle - trebleDrive * 0.20));

    _drawFighter(
      canvas,
      size,
      blueFoot,
      fighterScale,
      _blue,
      bass,
      bassPeak,
      phase,
      clash,
      mirrored: false,
      refined: false,
    );
    _drawFighter(
      canvas,
      size,
      purpleFoot,
      fighterScale,
      _purple,
      treble,
      treblePeak,
      -phase * 0.83,
      clash,
      mirrored: true,
      refined: true,
    );

    _drawParticles(canvas, size, minSide, phase, bass, treble, clash);
    if (clash > 0.015) _drawClash(canvas, Offset(w * 0.5, groundY - fighterScale * 0.67), minSide, clash, phase);
    _drawLabels(canvas, size, minSide, bass, treble, clash);
  }

  void _drawBackdrop(Canvas canvas, Size size, Offset center, double unit,
      double phase, double bass, double treble, double clash) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080A16), Color(0xFF090B18), Color(0xFF03050B)],
          stops: [0, 0.58, 1],
        ).createShader(rect),
    );
    final haloRect = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.51),
      width: size.width * 1.18,
      height: size.height * 0.78,
    );
    canvas.drawOval(
      haloRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _blue.withValues(alpha: 0.035 + bass * 0.065 + clash * 0.05),
            _purple.withValues(alpha: 0.025 + treble * 0.06 + clash * 0.05),
            Colors.transparent,
          ],
          stops: const [0, 0.48, 1],
        ).createShader(haloRect)
        ..blendMode = BlendMode.screen,
    );

    // Restrained split light columns and a distant arch frame the fighters.
    final arch = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.49),
      width: math.min(size.width * 0.90, unit * 1.66),
      height: unit * 1.84,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(arch, Radius.circular(unit * 0.82)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.035)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    for (var i = 0; i < 6; i++) {
      final side = i < 3 ? -1.0 : 1.0;
      final lane = i % 3;
      final x = center.dx + side * unit * (0.31 + lane * 0.14);
      final top = size.height * (0.16 + (lane % 2) * 0.05);
      final bottom = size.height * 0.72;
      final color = side < 0 ? _blue : _purple;
      final alpha = 0.018 + (lane == 0 ? 0.02 : 0.0) + clash * 0.035;
      canvas.drawLine(
        Offset(x, top),
        Offset(x + math.sin(phase * 0.35 + i) * unit * 0.025, bottom),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: alpha), Colors.transparent],
          ).createShader(Rect.fromLTRB(x - 1, top, x + 1, bottom))
          ..strokeWidth = lane == 0 ? 1.3 : 0.7,
      );
    }
    final centerLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.045 + clash * 0.04)
      ..strokeWidth = 0.7;
    canvas.drawLine(Offset(center.dx, size.height * 0.19), Offset(center.dx, size.height * 0.70), centerLine);
  }

  void _drawFloor(Canvas canvas, Size size, Offset center, double unit,
      double phase, double clash) {
    final floorRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + unit * 0.03),
      width: size.width * 0.94,
      height: unit * 0.34,
    );
    canvas.drawOval(
      floorRect,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.black.withValues(alpha: 0.72),
          Colors.black.withValues(alpha: 0.12),
          Colors.transparent,
        ]).createShader(floorRect),
    );
    final horizonY = center.dy + unit * 0.018;
    canvas.drawLine(
      Offset(size.width * 0.08, horizonY),
      Offset(size.width * 0.92, horizonY),
      Paint()
        ..shader = LinearGradient(colors: [
          _blue.withValues(alpha: 0.02),
          Colors.white.withValues(alpha: 0.12 + clash * 0.16),
          _purple.withValues(alpha: 0.02),
        ]).createShader(Rect.fromLTWH(size.width * 0.08, horizonY, size.width * 0.84, 1))
        ..strokeWidth = 0.8 + clash * 0.8,
    );
    for (var i = 0; i < 5; i++) {
      final spread = (i + 1) / 5;
      final y = horizonY + unit * (0.05 + spread * 0.18);
      final alpha = (0.025 * (1 - spread) + clash * 0.025).clamp(0.0, 0.07).toDouble();
      canvas.drawLine(
        Offset(center.dx - size.width * spread * 0.48, y),
        Offset(center.dx + size.width * spread * 0.48, y),
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
    final pulse = 0.75 + 0.25 * math.sin(phase * 1.1).abs();
    for (final entry in [(_blue, -1.0), (_purple, 1.0)]) {
      final x = center.dx + entry.$2 * unit * 0.48;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, horizonY), width: unit * 0.38, height: unit * 0.035),
        Paint()..color = entry.$1.withValues(alpha: 0.07 * pulse + clash * 0.08),
      );
    }
  }

  void _drawFighter(
    Canvas canvas,
    Size size,
    Offset foot,
    double scale,
    Color energyColor,
    double energy,
    double peak,
    double phase,
    double clash, {
    required bool mirrored,
    required bool refined,
  }) {
    final lean = (refined ? 0.012 : -0.018) + math.sin(phase * (refined ? 1.4 : 1.1)) * 0.014;
    final crouch = (refined ? energy * 0.018 : energy * 0.030) + peak * 0.010;
    final outlineAlpha = 0.39 + energy * 0.26 + peak * 0.16;
    final glow = config.glow
        ? (config.glowRadius * 0.23 / scale).clamp(0.006, 0.032).toDouble()
        : 0.0;

    canvas.save();
    canvas.translate(foot.dx, foot.dy);
    canvas.scale(mirrored ? -scale : scale, scale);
    canvas.rotate(lean - clash * (refined ? 0.10 : 0.14));
    canvas.translate(0, crouch);

    // Shadow and two separated leg planes give the silhouette a grounded duel stance.
    final shadow = Path()
      ..moveTo(-0.10, -0.27)
      ..quadraticBezierTo(-0.19, -0.16, -0.22, -0.025)
      ..lineTo(-0.065, 0)
      ..lineTo(0.005, -0.22)
      ..lineTo(0.09, -0.02)
      ..lineTo(0.205, 0.005)
      ..quadraticBezierTo(0.19, -0.13, 0.115, -0.30)
      ..close();
    _fillOutlined(canvas, shadow, energyColor, outlineAlpha * 0.52, glow * 0.55, width: 0.006);

    final rearLeg = Path()
      ..moveTo(-0.055, -0.37)
      ..lineTo(-0.145, -0.30)
      ..lineTo(-0.19, -0.105)
      ..lineTo(-0.235, -0.018)
      ..lineTo(-0.14, 0)
      ..lineTo(-0.055, -0.10)
      ..lineTo(0.03, -0.29)
      ..close();
    _fillOutlined(canvas, rearLeg, energyColor, outlineAlpha * 0.65, glow * 0.4, width: 0.006);

    final frontLeg = Path()
      ..moveTo(0.025, -0.39)
      ..lineTo(0.12, -0.32)
      ..lineTo(0.17, -0.13)
      ..lineTo(0.245, -0.025)
      ..lineTo(0.16, 0.002)
      ..lineTo(0.04, -0.10)
      ..lineTo(-0.045, -0.27)
      ..close();
    _fillOutlined(canvas, frontLeg, energyColor, outlineAlpha, glow * 0.5, width: 0.007);

    // Long split coat tails read clearly at small sizes without facial detail.
    final coat = Path()
      ..moveTo(-0.08, -0.60)
      ..quadraticBezierTo(-0.19, -0.46, -0.21, -0.28)
      ..lineTo(-0.255, -0.13)
      ..quadraticBezierTo(-0.17, -0.18, -0.12, -0.22)
      ..lineTo(-0.09, -0.07)
      ..lineTo(-0.015, -0.25)
      ..lineTo(0.055, -0.18)
      ..lineTo(0.11, -0.06)
      ..lineTo(0.145, -0.23)
      ..quadraticBezierTo(0.22, -0.43, 0.12, -0.59)
      ..close();
    _fillOutlined(canvas, coat, energyColor, outlineAlpha * 0.78, glow * 0.55, width: 0.008);

    // Torso, shoulder guards, and raised collar form an athletic silhouette.
    final torso = Path()
      ..moveTo(-0.075, -0.70)
      ..lineTo(0.065, -0.70)
      ..lineTo(0.125, -0.61)
      ..lineTo(0.105, -0.47)
      ..lineTo(0.06, -0.34)
      ..lineTo(-0.075, -0.35)
      ..lineTo(-0.12, -0.48)
      ..lineTo(-0.125, -0.62)
      ..close();
    _fillOutlined(canvas, torso, energyColor, outlineAlpha, glow * 0.62, width: 0.009);

    final shoulder = Path()
      ..moveTo(-0.12, -0.63)
      ..quadraticBezierTo(-0.20, -0.67, -0.22, -0.57)
      ..lineTo(-0.17, -0.49)
      ..lineTo(-0.095, -0.52)
      ..close();
    _fillOutlined(canvas, shoulder, energyColor, outlineAlpha * 0.78, glow * 0.35, width: 0.006);
    final forwardShoulder = Path()
      ..moveTo(0.07, -0.64)
      ..quadraticBezierTo(0.16, -0.68, 0.18, -0.57)
      ..lineTo(0.13, -0.49)
      ..lineTo(0.065, -0.53)
      ..close();
    _fillOutlined(canvas, forwardShoulder, energyColor, outlineAlpha, glow * 0.48, width: 0.007);

    // Back arm is tucked; forward arm reaches toward the opposing blade.
    final backArm = Path()
      ..moveTo(-0.12, -0.60)
      ..quadraticBezierTo(-0.19, -0.52, -0.16, -0.43)
      ..lineTo(-0.08, -0.39)
      ..lineTo(-0.035, -0.47)
      ..lineTo(-0.075, -0.55)
      ..close();
    _fillOutlined(canvas, backArm, energyColor, outlineAlpha * 0.70, glow * 0.25, width: 0.005);
    final armReach = Path()
      ..moveTo(0.11, -0.60)
      ..quadraticBezierTo(0.17, -0.57, 0.19, -0.52)
      ..lineTo(0.23, -0.48)
      ..lineTo(0.18, -0.43)
      ..lineTo(0.105, -0.48)
      ..lineTo(0.065, -0.54)
      ..close();
    _fillOutlined(canvas, armReach, energyColor, outlineAlpha, glow * 0.40, width: 0.006);

    // Head is featureless and masked: hair silhouette points toward the rival.
    final head = Path()
      ..moveTo(-0.045, -0.82)
      ..quadraticBezierTo(0.035, -0.86, 0.075, -0.79)
      ..quadraticBezierTo(0.11, -0.73, 0.075, -0.675)
      ..lineTo(0.035, -0.645)
      ..lineTo(-0.055, -0.66)
      ..quadraticBezierTo(-0.105, -0.70, -0.085, -0.77)
      ..close();
    _fillOutlined(canvas, head, energyColor, outlineAlpha, glow * 0.62, width: 0.008);
    final hair = Path()
      ..moveTo(-0.09, -0.755)
      ..lineTo(-0.15, -0.835)
      ..lineTo(-0.085, -0.815)
      ..lineTo(-0.10, -0.91)
      ..lineTo(-0.025, -0.85)
      ..lineTo(0.005, -0.94)
      ..lineTo(0.035, -0.84)
      ..lineTo(0.12, -0.865)
      ..lineTo(0.078, -0.78)
      ..quadraticBezierTo(0.005, -0.825, -0.09, -0.755)
      ..close();
    _fillOutlined(canvas, hair, energyColor, outlineAlpha * 0.92, glow * 0.52, width: 0.007);

    // Sparse armor inlays catch light but leave most of the figure dark.
    final detailPaint = Paint()
      ..color = energyColor.withValues(alpha: 0.30 + energy * 0.28 + peak * 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.006
      ..strokeCap = StrokeCap.round;
    final inlay = Path()
      ..moveTo(-0.045, -0.65)
      ..lineTo(-0.015, -0.57)
      ..lineTo(-0.035, -0.45)
      ..moveTo(0.075, -0.62)
      ..lineTo(0.035, -0.56)
      ..lineTo(0.055, -0.48);
    canvas.drawPath(inlay, detailPaint);
    canvas.drawLine(Offset(-0.09, -0.29), Offset(-0.145, -0.19), detailPaint);

    _drawSword(canvas, energyColor, energy, peak, phase, clash, refined, scale);
    canvas.restore();
  }

  void _drawSword(Canvas canvas, Color color, double energy, double peak,
      double phase, double clash, bool refined, double scale) {
    final hilt = Offset(0.205, -0.478);
    final baseTip = Offset(refined ? 0.585 : 0.61, refined ? -0.91 : -0.865);
    final sweep = math.sin(phase * (refined ? 2.1 : 1.55) + 0.5) * (refined ? 0.018 : 0.012);
    final tip = Offset(baseTip.dx + sweep + clash * 0.065, baseTip.dy - clash * 0.035);
    final edge = Offset(tip.dx - 0.074, tip.dy + 0.024);
    final guard = Offset(hilt.dx + 0.026, hilt.dy - 0.026);
    final pulse = (0.44 + energy * 0.22 + peak * 0.30 + clash * 0.22).clamp(0.0, 1.0).toDouble();
    final blade = Path()
      ..moveTo(hilt.dx + 0.012, hilt.dy - 0.022)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(edge.dx, edge.dy)
      ..lineTo(hilt.dx - 0.012, hilt.dy + 0.014)
      ..close();
    canvas.drawPath(
      blade,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            color.withValues(alpha: 0.20 + pulse * 0.28),
            Color.lerp(color, Colors.white, 0.72)!.withValues(alpha: 0.88),
            color.withValues(alpha: 0.48 + pulse * 0.45),
          ],
          stops: const [0, 0.48, 1],
        ).createShader(Rect.fromPoints(hilt, tip).inflate(0.035)),
    );
    final spine = Path()
      ..moveTo(hilt.dx + 0.004, hilt.dy - 0.015)
      ..lineTo(tip.dx - 0.018, tip.dy + 0.016);
    if (config.glow && pulse > 0.10) {
      canvas.drawPath(
        spine,
        Paint()
          ..color = color.withValues(alpha: 0.36 + pulse * 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.030 + peak * 0.018 + clash * 0.024
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (config.glowRadius * 0.20 / scale).clamp(0.006, 0.025).toDouble(),
          )
          ..blendMode = BlendMode.screen,
      );
    }
    canvas.drawPath(
      spine,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.70 + pulse * 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.006 + pulse * 0.003
        ..strokeCap = StrokeCap.round,
    );
    final guardPath = Path()
      ..moveTo(guard.dx - 0.058, guard.dy + 0.038)
      ..lineTo(guard.dx + 0.050, guard.dy - 0.050);
    canvas.drawPath(
      guardPath,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.018
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(hilt.dx - 0.032, hilt.dy + 0.034),
      Offset(hilt.dx + 0.035, hilt.dy - 0.034),
      Paint()
        ..color = Color.lerp(color, Colors.white, 0.34)!
        ..strokeWidth = 0.020
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(tip.dx - 0.016, tip.dy + 0.013),
      0.013 + peak * 0.010,
      Paint()
        ..color = color.withValues(alpha: 0.66 + peak * 0.28)
        ..maskFilter = config.glow
            ? MaskFilter.blur(
                BlurStyle.normal,
                ((2.0 + peak * 2.0) / scale).clamp(0.006, 0.025).toDouble(),
              )
            : null,
    );
  }

  void _drawParticles(Canvas canvas, Size size, double unit, double phase,
      double bass, double treble, double clash) {
    const count = 22;
    for (var i = 0; i < count; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final local = i ~/ 2;
      final speed = 0.35 + (local % 5) * 0.11;
      final drift = (phase * speed + local * 2.399963) % (2 * math.pi);
      final xUnit = side * (0.17 + ((local * 17) % 11) * 0.036) + math.sin(drift) * 0.024;
      final yUnit = 0.20 + ((local * 23) % 17) * 0.038 + math.cos(drift * 0.8) * 0.022;
      final point = Offset(size.width * 0.5 + xUnit * unit, size.height * yUnit);
      final energy = side < 0 ? bass : treble;
      final color = side < 0 ? _blue : _purple;
      final shimmer = (0.24 + 0.30 * math.sin(drift * 1.7 + i).abs() + energy * 0.34 + clash * 0.30)
          .clamp(0.10, 0.88)
          .toDouble();
      final radius = 0.75 + (local % 3) * 0.30 + energy * 0.55 + clash * 0.55;
      canvas.drawCircle(point, radius, Paint()..color = color.withValues(alpha: shimmer));
      if (i % 4 == 0 && shimmer > 0.43) {
        final tail = point - Offset(side * (3.0 + energy * 3.0), 4.0 + energy * 4.0);
        canvas.drawLine(tail, point, Paint()
          ..color = color.withValues(alpha: shimmer * 0.34)
          ..strokeWidth = 0.75
          ..strokeCap = StrokeCap.round);
      }
    }
  }

  void _drawClash(Canvas canvas, Offset point, double unit, double amount, double phase) {
    final pulse = amount * (0.84 + 0.16 * math.sin(phase * 2.8).abs());
    final radius = unit * (0.045 + (1 - amount) * 0.29);
    final flashRect = Rect.fromCircle(center: point, radius: unit * 0.12);
    canvas.drawCircle(
      point,
      unit * (0.11 + amount * 0.08),
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.60 * pulse),
          Color.lerp(_blue, _purple, 0.5)!.withValues(alpha: 0.25 * pulse),
          Colors.transparent,
        ], stops: const [0, 0.22, 1]).createShader(flashRect.inflate(unit * amount)),
    );
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 + amount * 2.0;
    canvas.drawCircle(point, radius, ringPaint);
    canvas.drawCircle(point, radius * 0.74,
      Paint()..color = _blue.withValues(alpha: 0.32 * pulse)..style = PaintingStyle.stroke..strokeWidth = 1.3);
    canvas.drawCircle(point, radius * 1.16,
      Paint()..color = _purple.withValues(alpha: 0.30 * pulse)..style = PaintingStyle.stroke..strokeWidth = 1.1);

    // Four short slashing rays imply crossed blades; the one-shot envelope fades them out.
    for (var i = 0; i < 4; i++) {
      final angle = math.pi * 0.25 + i * math.pi * 0.5 + phase * 0.13;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final start = point + direction * unit * 0.045;
      final end = point + direction * unit * (0.15 + amount * 0.10);
      canvas.drawLine(start, end, Paint()
        ..color = (i.isEven ? _blue : _purple).withValues(alpha: 0.52 * pulse)
        ..strokeWidth = 1.0 + amount * 1.8
        ..strokeCap = StrokeCap.round);
    }
  }

  void _drawLabels(Canvas canvas, Size size, double unit,
      double bass, double treble, double clash) {
    _label(canvas, Offset(size.width * 0.15, size.height * 0.145), 'BASS', 'BLUE FIGHTER', _blue, bass, true, unit);
    _label(canvas, Offset(size.width * 0.85, size.height * 0.145), 'TREBLE', 'PURPLE FIGHTER', _purple, treble, false, unit);
    final versus = TextPainter(
      text: TextSpan(text: clash > 0.08 ? 'CLASH' : 'VS', style: TextStyle(
        color: Colors.white.withValues(alpha: 0.30 + clash * 0.60),
        fontSize: clash > 0.08 ? 9 : 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    versus.paint(canvas, Offset(size.width * 0.5 - versus.width / 2, size.height * 0.17));
  }

  void _label(Canvas canvas, Offset position, String title, String subtitle,
      Color color, double energy, bool left, double unit) {
    final width = unit * 0.70;
    final align = left ? TextAlign.left : TextAlign.right;
    final text = TextPainter(
      text: TextSpan(children: [
        TextSpan(text: '$title\n', style: TextStyle(color: color.withValues(alpha: 0.66 + energy * 0.25), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
        TextSpan(text: subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.32), fontSize: 7, fontWeight: FontWeight.w600, letterSpacing: 1.3)),
      ]),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    text.paint(canvas, Offset(left ? position.dx : position.dx - text.width, position.dy));
    final lineY = position.dy + text.height + 7;
    final lineStart = left ? position.dx : position.dx - width;
    final lineEnd = left ? position.dx + width * (0.30 + energy * 0.34) : position.dx - width * (0.30 + energy * 0.34);
    canvas.drawLine(Offset(lineStart, lineY), Offset(lineEnd, lineY), Paint()
      ..color = color.withValues(alpha: 0.22 + energy * 0.40)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round);
  }

  void _fillOutlined(Canvas canvas, Path path, Color color, double alpha,
      double blur, {required double width}) {
    canvas.drawPath(path, Paint()..color = _silhouette);
    if (config.glow && blur > 0) {
      canvas.drawPath(path, Paint()
        ..color = color.withValues(alpha: alpha * 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 3.4
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
        ..blendMode = BlendMode.screen);
    }
    canvas.drawPath(path, Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round);
  }

  double _unit(double value) => value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
}
