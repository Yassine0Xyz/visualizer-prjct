import 'package:flutter/material.dart';

class VisualizerThemeData {
  const VisualizerThemeData({
    required this.name,
    required this.colors,
    required this.deepBackground,
    this.dynamicHue = true,
    this.accentColor,
  });

  final String name;
  final List<Color> colors;
  final Color deepBackground;
  final bool dynamicHue;
  final Color? accentColor;

  Color colorAt(double t, {double energy = 0, double bass = 0}) {
    final n = colors.length;
    if (n == 1) return colors.first;
    final x = t.clamp(0.0, 1.0).toDouble() * (n - 1);
    final i = x.floor().clamp(0, n - 2).toInt();
    var c = Color.lerp(colors[i], colors[i + 1], x - i)!;
    if (dynamicHue && (energy > 0.01 || bass > 0.1)) {
      final hsl = HSLColor.fromColor(c);
      final shift = (energy * 50 + bass * 30) % 360;
      c = hsl
          .withHue((hsl.hue + shift) % 360)
          .withLightness((hsl.lightness + energy * 0.15).clamp(0.0, 1.0).toDouble())
          .toColor();
    }
    return c;
  }

  static const List<VisualizerThemeData> presets = [
    VisualizerThemeData(
      name: 'Neon Nights',
      colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF), Color(0xFFFF2D9A), Color(0xFFFF9E00)],
      deepBackground: Color(0xFF050510),
    ),
    VisualizerThemeData(
      name: 'Sunset Drive',
      colors: [Color(0xFFFF9E00), Color(0xFFFF3D68), Color(0xFF8C1EFF), Color(0xFF00E5FF)],
      deepBackground: Color(0xFF0D0508),
      dynamicHue: false,
    ),
    VisualizerThemeData(
      name: 'Deep Ocean',
      colors: [Color(0xFF00FFA3), Color(0xFF00B8D9), Color(0xFF0052CC), Color(0xFF7C4DFF)],
      deepBackground: Color(0xFF03080D),
    ),
    VisualizerThemeData(
      name: 'Aurora',
      colors: [Color(0xFF64FFDA), Color(0xFF69F0AE), Color(0xFF40C4FF), Color(0xFF7C4DFF)],
      deepBackground: Color(0xFF03080C),
    ),
    VisualizerThemeData(
      name: 'Ember',
      colors: [Color(0xFFFFE082), Color(0xFFFF6D00), Color(0xFFD50000), Color(0xFFFF2D9A)],
      deepBackground: Color(0xFF0C0403),
      dynamicHue: false,
    ),
    VisualizerThemeData(
      name: 'Monolith',
      colors: [Color(0xFFECEFF1), Color(0xFF90A4AE), Color(0xFF37474F), Color(0xFF263238)],
      deepBackground: Color(0xFF050506),
      dynamicHue: false,
    ),
    VisualizerThemeData(
      name: 'Cyberpunk',
      colors: [Color(0xFFF72585), Color(0xFF7209B7), Color(0xFF3A0CA3), Color(0xFF4361EE)],
      deepBackground: Color(0xFF080510),
    ),
    VisualizerThemeData(
      name: 'Matrix',
      colors: [Color(0xFF00FF41), Color(0xFF008F11), Color(0xFF003B00), Color(0xFF00E5FF)],
      deepBackground: Color(0xFF000800),
    ),
  ];
}
