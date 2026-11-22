import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/player/player_controller.dart';
import 'features/player/screens/home_screen.dart';

class VisualizerLabApp extends StatefulWidget {
  const VisualizerLabApp({super.key});

  @override
  State<VisualizerLabApp> createState() => _VisualizerLabAppState();
}

class _VisualizerLabAppState extends State<VisualizerLabApp> {
  late final PlayerController controller = PlayerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visualizer Lab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: HomeScreen(controller: controller),
    );
  }
}
