import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/visualizer_painter.dart';

/// A restrained, audio-reactive botanical scene for the night garden.
class FractalBloomNightGardenPainter extends VisualizerPainter {
  FractalBloomNightGardenPainter(super.data, super.config, super.theme);

  double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }
    final w = size.width;
    final h = size.height;
    final m = math.min(w, h);
    final rect = Offset.zero & size;
    final energy = _unit(data.energy);
    final bass = _unit(data.bass);
    final mid = _unit(data.mid);
    final high = _unit(data.high);
    final phase = data.phase.isFinite ? data.phase : 0.0;
    final values = data.values;
    final previous = data.previousValues;
    double band(double t) {
      if (values.isEmpty) return 0;
      final i = ((values.length - 1) * t).round().clamp(0, values.length - 1);
      final now = _unit(values[i]);
      return i < previous.length ? _unit(previous[i]) * .2 + now * .8 : now;
    }

    canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -.42),
            radius: 1.22,
            colors: [
              const Color(0xFF132638),
              const Color(0xFF07101B),
              const Color(0xFF03070D)
            ],
            stops: const [0, .58, 1],
          ).createShader(rect));
    final moonCenter = Offset(w * .72, h * .24);
    final moonRect = Rect.fromCircle(center: moonCenter, radius: m * .32);
    canvas.drawCircle(
        moonCenter,
        m * .32,
        Paint()
          ..shader = RadialGradient(colors: [
            colorAt(.56, energy: energy, bass: bass)
                .withValues(alpha: .13 + energy * .08),
            Colors.transparent,
          ]).createShader(moonRect)
          ..blendMode = BlendMode.screen);
    canvas.drawCircle(
        moonCenter,
        m * .105,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFCFD8C3),
            const Color(0xFF71899A).withValues(alpha: .12),
            Colors.transparent,
          ], stops: const [
            0,
            .58,
            1
          ]).createShader(
              Rect.fromCircle(center: moonCenter, radius: m * .105)));

    final horizon = h * .76;
    canvas.drawRect(
        Rect.fromLTWH(0, horizon - h * .11, w, h * .22),
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x003E6B68),
                const Color(0x333E6B68),
                const Color(0x003E6B68)
              ]).createShader(Rect.fromLTWH(0, horizon - h * .11, w, h * .22))
          ..blendMode = BlendMode.screen);

    void stem(Offset start, double angle, double length, double thickness,
        int seed, int depth, double alpha) {
      if (length < m * .014) return;
      final swing = math.sin(phase * (.19 + depth * .025) + seed * 1.7) *
          (.025 + mid * .045);
      final a = angle + swing;
      final end = start + Offset(math.cos(a), math.sin(a)) * length;
      final normal = Offset(-math.sin(a), math.cos(a));
      final bend = normal *
          length *
          (.07 + mid * .035 + math.sin(phase * .13 + seed) * .012);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
            start.dx + (end.dx - start.dx) * .29 + bend.dx,
            start.dy + (end.dy - start.dy) * .29 + bend.dy,
            start.dx + (end.dx - start.dx) * .72 + bend.dx * .45,
            start.dy + (end.dy - start.dy) * .72 + bend.dy * .45,
            end.dx,
            end.dy);
      final tint = colorAt(.22 + depth * .12 + band((seed * .17) % 1) * .18,
          energy: energy, bass: bass);
      if (config.glow && depth > 0) {
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = thickness * 2.8
              ..color = tint.withValues(alpha: .055 + energy * .045)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2)
              ..blendMode = BlendMode.screen);
      }
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = thickness
            ..shader = LinearGradient(colors: [
              const Color(0xFF172B2B).withValues(alpha: alpha),
              tint.withValues(alpha: alpha * .8),
              const Color(0xFF718577).withValues(alpha: alpha * .62),
            ]).createShader(Rect.fromPoints(start, end)));
      // A few intentional forks, not a recursive fractal.
      if (depth == 2) {
        stem(end, a - .62, length * .55, thickness * .57, seed + 3, 1,
            alpha * .92);
        stem(end, a + .68, length * .48, thickness * .52, seed + 7, 1,
            alpha * .88);
      } else if (depth == 1 && seed % 2 == 0) {
        stem(end, a - .42, length * .52, thickness * .48, seed + 2, 0,
            alpha * .72);
      }
    }

    final growth = .91 +
        bass * .10 +
        band(.12) * .035 +
        math.sin(phase * .11) * (.012 + energy * .012);
    final roots = <Offset>[
      Offset(w * .10, h * 1.03),
      Offset(w * .36, h * 1.05),
      Offset(w * .67, h * 1.04),
      Offset(w * .91, h * 1.02),
    ];
    final angles = <double>[-1.18, -1.73, -1.43, -1.98];
    for (var i = 0; i < roots.length; i++) {
      stem(roots[i], angles[i], m * (.29 + (i.isEven ? .07 : 0)) * growth,
          m * (.012 + bass * .004) * (i == 1 || i == 2 ? 1 : .8), i, 2, .88);
    }

    final buds = <Offset>[
      Offset(w * .20, h * .46),
      Offset(w * .43, h * .34),
      Offset(w * .61, h * .49),
      Offset(w * .82, h * .40),
      Offset(w * .34, h * .60),
    ];
    for (var i = 0; i < buds.length; i++) {
      final p = buds[i];
      final pulse = (bass * .18 + band(.2 + i * .13) * .12 + energy * .09)
          .clamp(0.0, .34)
          .toDouble();
      final radius = m * (.012 + pulse * .045);
      final color = colorAt(.45 + i * .105, energy: energy, bass: bass);
      if (config.glow) {
        canvas.drawCircle(
            p,
            radius * 3.3,
            Paint()
              ..shader = RadialGradient(colors: [
                color.withValues(alpha: .24 + pulse * .3),
                Colors.transparent
              ]).createShader(Rect.fromCircle(center: p, radius: radius * 3.3))
              ..blendMode = BlendMode.screen);
      }
      final bud = Path()
        ..moveTo(p.dx, p.dy + radius * 1.25)
        ..quadraticBezierTo(
            p.dx - radius * 1.18, p.dy + radius * .1, p.dx, p.dy - radius * 1.3)
        ..quadraticBezierTo(p.dx + radius * 1.12, p.dy + radius * .12, p.dx,
            p.dy + radius * 1.25)
        ..close();
      canvas.drawPath(
          bud,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFF4E8C8).withValues(alpha: .94),
              color.withValues(alpha: .9),
              color.withValues(alpha: .34),
            ], stops: const [
              0,
              .28,
              1
            ]).createShader(Rect.fromCircle(center: p, radius: radius * 1.4)));
      canvas.drawCircle(
          p, radius * .18, Paint()..color = Colors.white.withValues(alpha: .8));
    }

    if (config.particles && m > 45) {
      const dew = <Offset>[
        Offset(.13, .29),
        Offset(.29, .20),
        Offset(.53, .25),
        Offset(.91, .31),
        Offset(.75, .57),
        Offset(.08, .63)
      ];
      for (var i = 0; i < dew.length; i++) {
        final p = Offset(w * dew[i].dx, h * dew[i].dy);
        final alpha =
            (.18 + high * .28 + math.sin(phase * .24 + i * 2.1).abs() * .12)
                .clamp(0.0, .58)
                .toDouble();
        final r = m * (.0015 + high * .0012);
        canvas.drawCircle(p, r,
            Paint()..color = const Color(0xFFD8E8D8).withValues(alpha: alpha));
      }
    }

    final foreground = Path()
      ..moveTo(0, h * .94)
      ..quadraticBezierTo(w * .18, h * .84, w * .35, h)
      ..lineTo(0, h)
      ..close();
    final right = Path()
      ..moveTo(w, h * .91)
      ..quadraticBezierTo(w * .78, h * .86, w * .65, h)
      ..lineTo(w, h)
      ..close();
    final silhouette = Paint()
      ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Color(0xFF122322), Color(0xFF050B10)])
          .createShader(Rect.fromLTWH(0, h * .84, w, h * .16));
    canvas.drawPath(foreground, silhouette);
    canvas.drawPath(right, silhouette);
  }
}
