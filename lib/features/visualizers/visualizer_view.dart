import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'base/visualizer_painter.dart';
import 'styles/bars_painter.dart';
import 'styles/bass_circle_painter.dart';
import 'styles/circular_painter.dart';
import 'styles/circular_wave_painter.dart';
import 'styles/columns_painter.dart';
import 'styles/fluid_painter.dart';
import 'styles/fluid_bass_painter.dart';
import 'styles/frequency_rings_painter.dart';
import 'styles/geometric_painter.dart';
import 'styles/mirror_painter.dart';
import 'styles/neon_bars_painter.dart';
import 'styles/particle_explosion_painter.dart';
import 'styles/particles_painter.dart';
import 'styles/pulsing_center_painter.dart';
import 'styles/radial_painter.dart';
import 'styles/spectrum_rings_painter.dart';
import 'styles/wave_painter.dart';
import 'styles/waterfall_painter.dart';
import 'styles/oscilloscope_painter.dart';
import 'styles/duel_painter.dart';
import 'styles/energy_wave_painter.dart';
import 'styles/aurora_flow_painter.dart';
import 'styles/radial_spectrogram_painter.dart';
import 'styles/lissajous_stereo_painter.dart';
import 'styles/prism_bloom_painter.dart';
import 'styles/harmonic_skyline_painter.dart';
import 'styles/liquid_chrome_painter.dart';
import 'styles/orbiting_particles_painter.dart';
import 'styles/fractal_bloom_painter.dart';
import 'styles/anime_fighters_painter.dart';
import 'styles/neon_afterglow_painter.dart';
import 'styles/orbiting_particles_halo_painter.dart';
import 'styles/fractal_bloom_nightgarden_painter.dart';
import 'styles/nebula_rift_painter.dart';
import 'styles/holo_arena_painter.dart';
import 'visualizer_config.dart';
import 'visualizer_data.dart';
import 'visualizer_style.dart';
import 'visualizer_theme.dart';

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
    VisualizerStyle.neonBars => NeonBarsPainter(data, config, theme),
    VisualizerStyle.bassCircle => BassCirclePainter(data, config, theme),
    VisualizerStyle.frequencyRings => FrequencyRingsPainter(data, config, theme),
    VisualizerStyle.energyWave => EnergyWavePainter(data, config, theme),
    VisualizerStyle.particleExplosion => ParticleExplosionPainter(data, config, theme),
    VisualizerStyle.pulsingCenter => PulsingCenterPainter(data, config, theme),
    VisualizerStyle.spectrumRings => SpectrumRingsPainter(data, config, theme),
    VisualizerStyle.fluidBass => FluidBassPainter(data, config, theme),
    VisualizerStyle.circularWave => CircularWavePainter(data, config, theme),
    VisualizerStyle.waterfall => WaterfallPainter(data, config, theme),
    VisualizerStyle.oscilloscope => OscilloscopePainter(data, config, theme),
    VisualizerStyle.duel => DuelPainter(data, config, theme),
    VisualizerStyle.auroraFlow => AuroraFlowPainter(data, config, theme),
    VisualizerStyle.radialSpectrogram => RadialSpectrogramPainter(data, config, theme),
    VisualizerStyle.lissajousStereo => LissajousStereoPainter(data, config, theme),
    VisualizerStyle.prismBloom => PrismBloomPainter(data, config, theme),
    VisualizerStyle.harmonicSkyline => HarmonicSkylinePainter(data, config, theme),
    VisualizerStyle.liquidChrome => LiquidChromePainter(data, config, theme),
    VisualizerStyle.orbitingParticles => OrbitingParticlesPainter(data, config, theme),
    VisualizerStyle.fractalBloom => FractalBloomPainter(data, config, theme),
    VisualizerStyle.animeFighters => AnimeFightersPainter(data, config, theme),
    VisualizerStyle.neonAfterglow => NeonAfterglowPainter(data, config, theme),
    VisualizerStyle.orbitingHalo => OrbitingParticlesHaloPainter(data, config, theme),
    VisualizerStyle.nightGarden => FractalBloomNightGardenPainter(data, config, theme),
    VisualizerStyle.nebulaRift => NebulaRiftPainter(data, config, theme),
    VisualizerStyle.holoArena => HoloArenaPainter(data, config, theme),
  };
}

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
    _ticker = createTicker((_) => widget.onTick())..start();
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
        animation: Listenable.merge([widget.data, widget.config]),
        builder: (context, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 1.06, end: 1.0).animate(animation),
                child: child,
              ),
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
