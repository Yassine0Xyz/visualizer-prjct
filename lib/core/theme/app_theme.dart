import 'package:flutter/material.dart';

/// Premium dark theme shared by the whole lab.
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
      scaffoldBackgroundColor: const Color(0xFF07070D),
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

/// Small helper: glassmorphic container decoration.
BoxDecoration glassDecoration({double radius = 24, Color? tint}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: (tint ?? Colors.white).withValues(alpha: 0.06),
    border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
  );
}
