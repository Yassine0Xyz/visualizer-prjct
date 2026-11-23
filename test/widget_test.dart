import 'package:audio_visualizer_lab_v2/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app theme uses the dark color scheme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: Text('Visualizer Lab')),
      ),
    );

    final context = tester.element(find.text('Visualizer Lab'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
