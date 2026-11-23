import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const seed = Color(0xFF7C4DFF);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF050508),
      splashFactory: InkSparkle.splashFactory,
      sliderTheme: const SliderThemeData(
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }
}

BoxDecoration glassDecoration({double radius = 24, Color? tint}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: (tint ?? Colors.white).withValues(alpha: 0.04),
    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
