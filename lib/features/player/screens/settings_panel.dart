import 'package:flutter/material.dart';
import '../../visualizers/visualizer_theme.dart';
import '../player_controller.dart';

Future<void> showSettingsSheet(BuildContext context, PlayerController controller) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0C0C18),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => _SettingsSheet(controller: controller),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final config = controller.config;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([controller, config]),
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white20,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Visualizer Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),

                _SliderRow(
                  label: 'Sensitivity',
                  value: config.sensitivity,
                  min: 0.2,
                  max: 4.0,
                  onChanged: (v) => config.sensitivity = v,
                ),
                _SliderRow(
                  label: 'Smoothness',
                  value: config.smoothness,
                  min: 0.0,
                  max: 0.95,
                  onChanged: (v) => config.smoothness = v,
                ),
                _SliderRow(
                  label: 'Intensity',
                  value: config.intensity,
                  min: 0.3,
                  max: 2.5,
                  onChanged: (v) => config.intensity = v,
                ),
                _SliderRow(
                  label: 'Bass Boost',
                  value: config.bassBoost,
                  min: 0.5,
                  max: 3.0,
                  onChanged: (v) => config.bassBoost = v,
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Glow Effect', style: TextStyle(fontSize: 14)),
                  value: config.glow,
                  onChanged: (v) => config.glow = v,
                ),
                if (config.glow)
                  _SliderRow(
                    label: 'Glow Radius',
                    value: config.glowRadius,
                    min: 0,
                    max: 32,
                    onChanged: (v) => config.glowRadius = v,
                  ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Particles', style: TextStyle(fontSize: 14)),
                  value: config.particles,
                  onChanged: (v) => config.particles = v,
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mirror Mode', style: TextStyle(fontSize: 14)),
                  value: config.mirror,
                  onChanged: (v) => config.mirror = v,
                ),

                const SizedBox(height: 16),
                const Text('Color Theme',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final t in VisualizerThemeData.presets)
                      ChoiceChip(
                        label: Text(t.name),
                        selected: controller.theme == t,
                        showCheckmark: false,
                        onSelected: (_) => controller.selectTheme(t),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
