import 'package:flutter/material.dart';

/// The selectable visualizer collection. Each style has a distinct visual
/// identity and animation behavior; all share the same [AudioFrame] input.
enum VisualizerStyle {
  bars,
  wave,
  columns,
  mirror,
  circular,
  radial,
  fluid,
  particles,
  geometry;

  String get label => switch (this) {
        VisualizerStyle.bars => 'Bars',
        VisualizerStyle.wave => 'Wave',
        VisualizerStyle.columns => 'Columns',
        VisualizerStyle.mirror => 'Mirror',
        VisualizerStyle.circular => 'Circular',
        VisualizerStyle.radial => 'Radial',
        VisualizerStyle.fluid => 'Fluid',
        VisualizerStyle.particles => 'Particles',
        VisualizerStyle.geometry => 'Geometry',
      };

  String get description => switch (this) {
        VisualizerStyle.bars => 'Classic bottom-anchored spectrum bars with rounded caps and glow.',
        VisualizerStyle.wave => 'A smooth interpolated spectrum line with a soft gradient fill.',
        VisualizerStyle.columns => 'An equalizer wall of glowing blocks arranged in a grid.',
        VisualizerStyle.mirror => 'Symmetric bars expanding above and below a luminous center line.',
        VisualizerStyle.circular => 'Frequency bars arranged around a ring, rotating with the beat.',
        VisualizerStyle.radial => 'A filled polar spectrum blob with an echoing inner contour.',
        VisualizerStyle.fluid => 'Layered liquid waves driven by bass, mids and highs.',
        VisualizerStyle.particles => 'A field of particles pushed outward by the spectrum.',
        VisualizerStyle.geometry => 'Rotating low-poly rings that breathe with the frequency bands.',
      };

  IconData get icon => switch (this) {
        VisualizerStyle.bars => Icons.bar_chart_rounded,
        VisualizerStyle.wave => Icons.show_chart_rounded,
        VisualizerStyle.columns => Icons.grid_on_rounded,
        VisualizerStyle.mirror => Icons.unfold_more_rounded,
        VisualizerStyle.circular => Icons.radio_button_unchecked_rounded,
        VisualizerStyle.radial => Icons.blur_circular_rounded,
        VisualizerStyle.fluid => Icons.waves_rounded,
        VisualizerStyle.particles => Icons.scatter_plot_rounded,
        VisualizerStyle.geometry => Icons.hexagon_outlined,
      };
}
