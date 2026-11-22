import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'base/visualizer_painter.dart';
import 'styles/bars_painter.dart';
import 'styles/circular_painter.dart';
import 'styles/columns_painter.dart';
import 'styles/fluid_painter.dart';
import 'styles/geometric_painter.dart';
import 'styles/mirror_painter.dart';
import 'styles/particles_painter.dart';
import 'styles/radial_painter.dart';
import 'styles/wave_painter.dart';
import 'visualizer_config.dart';
import 'visualizer_data.dart';
import 'visualizer_style.dart';
import 'visualizer_theme.dart';

/// Creates the painter matching [style]. This is the only place that maps a
/// style to its renderer.
VisualizerPainter createPainter(
  VisualizerStyle style,
  VisualizerData data,
  VisualizerConfig config,
  VisualizerThemeData theme,
) {
  return switch (style) {
    VisualizerStyle.bars => BarsPainter(data, config, theme),
    VisualizerStyle.wave => WavePainter(data, config, theme),
    VisualizerStyle.columns => ColumnsPainter(data, config, theme),
    VisualizerStyle.mirror => MirrorPainter(data, config, theme),
    VisualizerStyle.circular => CircularPainter(data, config, theme),
    VisualizerStyle.radial => RadialPainter(data, config, theme),
    VisualizerStyle.fluid => FluidPainter(data, config, theme),
    VisualizerStyle.particles => ParticlesPainter(data, config, theme),
    VisualizerStyle.geometry => GeometricPainter(data, config, theme),
  };
}

/// Renders the active visualizer, driving data updates from a [Ticker] so the
/// visuals advance at the display's refresh rate (60/90/120 Hz).
class VisualizerView extends StatefulWidget {
  const VisualizerView({
    super.key,
    required this.data,
    required this.config,
    required this.theme,
    required this.style,
    required this.onTick,
  });

  final VisualizerData data;
  final VisualizerConfig config;
  final VisualizerThemeData theme;
  final VisualizerStyle style;

  /// Called on every display frame; the controller should push the latest
  /// interpolated analysis frame into [data].
  final VoidCallback onTick;

  @override
  State<VisualizerView> createState() => _VisualizerViewState();
}

class _VisualizerViewState extends State<VisualizerView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      widget.onTick();
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: widget.data,
        builder: (context, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: Tween(begin: 1.04, end: 1.0).animate(animation), child: child),
            ),
            child: CustomPaint(
              key: ValueKey(widget.style),
              painter: createPainter(widget.style, widget.data, widget.config, widget.theme),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}
