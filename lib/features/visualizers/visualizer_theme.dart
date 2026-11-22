import 'package:flutter/material.dart';

/// Color identity for visualizers. Colors are sampled along a gradient via
/// [colorAt]; when [dynamicHue] is enabled the gradient slowly rotates with
/// the music energy.
class VisualizerThemeData {
  const VisualizerThemeData({
    required this.name,
    required this.colors,
    required this.deepBackground,
    this.dynamicHue = true,
  });

  final String name;
  final List<Color> colors;
  final Color deepBackground;

  /// Shift hue with energy for a "living palette".
  final bool dynamicHue;

  Color colorAt(double t, {double energy = 0}) {
    final n = colors.length;
    if (n == 1) return colors.first;
    final x = t.clamp(0.0, 1.0) * (n - 1);
    final i = x.floor().clamp(0, n - 2);
    var c = Color.lerp(colors[i], colors[i + 1], x - i)!;
    if (dynamicHue && energy > 0.01) {
      final hsl = HSLColor.fromColor(c);
      c = hsl
          .withHue((hsl.hue + energy * 40) % 360)
          .withLightness((hsl.lightness + energy * 0.12).clamp(0.0, 1.0))
          .toColor();
    }
    return c;
  }

  static const List<VisualizerThemeData> presets = [
    VisualizerThemeData(
      name: 'Neon Nights',
      colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF), Color(0xFFFF2D9A)],
      deepBackground: Color(0xFF07070D),
    ),
    VisualizerThemeData(
      name: 'Sunset Drive',
      colors: [Color(0xFFFF9E00), Color(0xFFFF3D68), Color(0xFF8C1EFF)],
      deepBackground: Color(0xFF0D0607),
      dynamicHue: false,
    ),
    VisualizerThemeData(
      name: 'Deep Ocean',
      colors: [Color(0xFF00FFA3), Color(0xFF00B8D9), Color(0xFF0052CC)],
      deepBackground: Color(0xFF03090D),
    ),
    VisualizerThemeData(
      name: 'Aurora',
      colors: [Color(0xFF64FFDA), Color(0xFF69F0AE), Color(0xFF40C4FF)],
      deepBackground: Color(0xFF04070C),
    ),
    VisualizerThemeData(
      name: 'Ember',
      colors: [Color(0xFFFFE082), Color(0xFFFF6D00), Color(0xFFD50000)],
      deepBackground: Color(0xFF0C0503),
      dynamicHue: false,
    ),
    VisualizerThemeData(
      name: 'Monolith',
      colors: [Color(0xFFECEFF1), Color(0xFF90A4AE), Color(0xFF37474F)],
      deepBackground: Color(0xFF050607),
      dynamicHue: false,
    ),
  ];
}
