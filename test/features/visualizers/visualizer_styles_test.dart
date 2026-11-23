import 'dart:ui' as ui;

import 'package:audio_visualizer_lab_v2/features/visualizers/base/visualizer_painter.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_config.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_data.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_style.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_theme.dart';
import 'package:audio_visualizer_lab_v2/features/visualizers/visualizer_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all 20 visualizer styles create and paint without throwing', () {
    expect(VisualizerStyle.values, hasLength(20));
    final data = VisualizerData();
    final config = VisualizerConfig();
    final theme = VisualizerThemeData.presets.first;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    for (final style in VisualizerStyle.values) {
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
}
