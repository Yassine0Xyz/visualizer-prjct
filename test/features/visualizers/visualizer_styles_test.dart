import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:audio_visualizer_lab_v2/features/visualizers/base/visualizer_painter.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_config.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_data.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_style.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_theme.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Duel applies the same response to equal stereo channel energies', () {
    final data = VisualizerData()..setStopped(false);
    data.update(
      Float32List(VisualizerData.bandCount),
      0, 0, 0, 0, 0, 0, 0, 0.5,
      null, null, 0.8, 0.8,
    );
    expect(data.duelLeftEnergy, data.duelRightEnergy);
    data.dispose();
  });

  test('Duel supports a Bass versus Treble matchup', () {
    final data = VisualizerData();
    final config = VisualizerConfig()..duelMode = DuelMode.bassVsTreble;
    final theme = VisualizerThemeData.presets.first;
    data.bass = 0.75;
    data.high = 0.35;

    expect(config.duelMode, DuelMode.bassVsTreble);
    final painter = createPainter(VisualizerStyle.duel, data, config, theme);
    final recorder = ui.PictureRecorder();
    expect(
      () => painter.paint(ui.Canvas(recorder), const ui.Size(400, 800)),
      returnsNormally,
    );

    recorder.endRecording().dispose();
    data.dispose();
    config.dispose();
  });

  test('Anime Fighters is independent and clashes on synchronized rises', () {
    final data = VisualizerData()..setStopped(false);
    final config = VisualizerConfig()..duelMode = DuelMode.bassVsTreble;
    final theme = VisualizerThemeData.presets.first;
    final painter = createPainter(VisualizerStyle.animeFighters, data, config, theme);
    expect(painter, isNot(createPainter(VisualizerStyle.duel, data, config, theme)));
    expect(config.duelMode, DuelMode.bassVsTreble);

    final recorder = ui.PictureRecorder();
    expect(() => painter.paint(ui.Canvas(recorder), const ui.Size(400, 800)), returnsNormally);
    recorder.endRecording().dispose();

    data.update(
      Float32List(VisualizerData.bandCount),
      0.8, 0, 0.8, 0.6, 0.4, 0, 0.4, 0.5,
      null, null, 0, 0,
    );
    expect(data.fighterClashProgress, greaterThan(0));
    for (var frame = 0; frame < 16; frame++) {
      data.update(
        Float32List(VisualizerData.bandCount),
        0.8, 0, 0.8, 0.6, 0.4, 0, 0.4, 0.5,
        null, null, 0, 0,
      );
    }
    expect(data.fighterClashProgress, inInclusiveRange(0.34, 0.46));
    expect(data.fighterClash, greaterThan(0.9));

    final next = ui.PictureRecorder();
    createPainter(VisualizerStyle.animeFighters, data, config, theme)
        .paint(ui.Canvas(next), const ui.Size(400, 800));
    next.endRecording().dispose();
    for (var frame = 0; frame < 23; frame++) {
      data.update(
        Float32List(VisualizerData.bandCount),
        0.8, 0, 0.8, 0.6, 0.4, 0, 0.4, 0.5,
        null, null, 0, 0,
      );
    }
    expect(data.fighterClash, 0);
    expect(data.fighterClashProgress, 0);
    data.dispose();
    config.dispose();
  });

  test('Duel victory aura follows the leading source in both modes', () {
    final data = VisualizerData();
    final config = VisualizerConfig();
    final theme = VisualizerThemeData.presets.first;
    data.duelLeftEnergy = 0.92;
    data.duelRightEnergy = 0.14;

    var recorder = ui.PictureRecorder();
    var painter = createPainter(VisualizerStyle.duel, data, config, theme);
    expect(
      () => painter.paint(ui.Canvas(recorder), const ui.Size(400, 800)),
      returnsNormally,
    );
    recorder.endRecording().dispose();

    config.duelMode = DuelMode.bassVsTreble;
    data.bass = 0.12;
    data.high = 0.94;
    recorder = ui.PictureRecorder();
    painter = createPainter(VisualizerStyle.duel, data, config, theme);
    expect(
      () => painter.paint(ui.Canvas(recorder), const ui.Size(400, 800)),
      returnsNormally,
    );
    recorder.endRecording().dispose();

    data.dispose();
    config.dispose();
  });

  test('Orbiting Particles and Fractal Bloom render across audio and screen ranges', () {
    final data = VisualizerData();
    final config = VisualizerConfig();
    final theme = VisualizerThemeData.presets.first;
    const sizes = [ui.Size(400, 800), ui.Size(800, 420), ui.Size(144, 256)];

    for (final style in [VisualizerStyle.orbitingParticles, VisualizerStyle.fractalBloom]) {
      final painter = createPainter(style, data, config, theme);
      for (final level in [0.0, 0.35, 0.75, 1.0]) {
        data.bass = level;
        data.mid = (level * 0.82).clamp(0.0, 1.0).toDouble();
        data.high = (level * 0.93).clamp(0.0, 1.0).toDouble();
        data.energy = level;
        data.phase = level * 120;
        data.values.fillRange(0, data.values.length, level);

        for (final size in sizes) {
          final recorder = ui.PictureRecorder();
          expect(
            () => painter.paint(ui.Canvas(recorder), size),
            returnsNormally,
            reason: '$style failed at $level audio intensity on $size',
          );
          recorder.endRecording().dispose();
        }
      }
    }

    data.dispose();
    config.dispose();
  });

  test('all visualizer styles create and paint without throwing', () {
    expect(VisualizerStyle.values, hasLength(35));
    final data = VisualizerData();
    final config = VisualizerConfig();
    final theme = VisualizerThemeData.presets.first;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    for (final style in VisualizerStyle.values) {
      expect(style.label, isNotEmpty, reason: 'Missing label for $style');
      expect(style.description, isNotEmpty, reason: 'Missing description for $style');
      final painter = createPainter(style, data, config, theme);
      expect(painter, isA<VisualizerPainter>(), reason: 'Missing painter for $style');
      expect(
        () => painter.paint(canvas, const ui.Size(400, 800)),
        returnsNormally,
        reason: 'Painter failed for $style',
      );
    }

    recorder.endRecording().dispose();
    data.dispose();
    config.dispose();
  });

  test('modified visualizer variants expose their source styles', () {
    expect(VisualizerStyle.neonAfterglow.isModifiedCopy, isTrue);
    expect(VisualizerStyle.neonAfterglow.copySource, 'Neon Bars');
    expect(VisualizerStyle.orbitingHalo.copySource, 'Orbiting Particles');
    expect(VisualizerStyle.nightGarden.copySource, 'Fractal Bloom');
    expect(VisualizerStyle.neonBars.isModifiedCopy, isFalse);

    final data = VisualizerData();
    final config = VisualizerConfig();
    final theme = VisualizerThemeData.presets.first;
    for (final style in [
      VisualizerStyle.neonAfterglow,
      VisualizerStyle.orbitingHalo,
      VisualizerStyle.nightGarden,
    ]) {
      final recorder = ui.PictureRecorder();
      expect(
        () => createPainter(style, data, config, theme)
            .paint(ui.Canvas(recorder), const ui.Size(144, 256)),
        returnsNormally,
      );
      recorder.endRecording().dispose();
    }
    data.dispose();
    config.dispose();
  });

  test('Nebula Rift and Holo Arena render at compact, portrait, and landscape sizes', () {
    final data = VisualizerData();
    final config = VisualizerConfig();
    final theme = VisualizerThemeData.presets.first;
    const sizes = [ui.Size(144, 256), ui.Size(400, 800), ui.Size(800, 420)];
    for (final style in [VisualizerStyle.nebulaRift, VisualizerStyle.holoArena]) {
      for (final level in [0.0, 0.45, 1.0]) {
        data.energy = level;
        data.bass = level * 0.82;
        data.mid = level * 0.67;
        data.high = level * 0.91;
        data.phase = level * 37;
        data.values.fillRange(0, data.values.length, level);
        final painter = createPainter(style, data, config, theme);
        for (final size in sizes) {
          final recorder = ui.PictureRecorder();
          expect(
            () => painter.paint(ui.Canvas(recorder), size),
            returnsNormally,
            reason: '$style failed at level $level on $size',
          );
          recorder.endRecording().dispose();
        }
      }
    }
    data.dispose();
    config.dispose();
  });
}
