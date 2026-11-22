import 'package:flutter/material.dart';

import '../../visualizers/visualizer_style.dart';
import '../player_controller.dart';
import 'visualizer_screen.dart';

/// Landing screen: import audio, then jump into the visualizer lab.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0714), Color(0xFF07070D), Color(0xFF03100F)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [scheme.primary, scheme.tertiary],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withOpacity(0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.graphic_eq_rounded, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visualizer Lab',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Audio-reactive visualizer research playground',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Import card
                  _GlassCard(
                    onTap: controller.isLoading ? null : controller.importAudio,
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: controller.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : const Icon(Icons.upload_file_rounded, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.isLoading ? 'Working…' : 'Import audio',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.isLoading
                                    ? controller.statusMessage
                                    : 'Pick a local track to start experimenting',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: Colors.white38),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (controller.hasTrack)
                    _GlassCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VisualizerScreen(controller: controller),
                        ),
                      ),
                      tint: scheme.primary,
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_fill_rounded, size: 40),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.track!.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Continue session',
                                  style: TextStyle(
                                    color: scheme.primary.withOpacity(0.9),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 36),
                  const Text(
                    'Visualizer styles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Each style has its own identity — all driven by real FFT data.',
                    style: TextStyle(color: Colors.white38, fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      for (final s in VisualizerStyle.values)
                        _StyleCard(
                          style: s,
                          selected: controller.style == s,
                          onTap: () {
                            controller.selectStyle(s);
                            if (controller.hasTrack) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VisualizerScreen(controller: controller),
                                ),
                              );
                            } else {
                              controller.importAudio();
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Standalone experiment · no connection to any other project',
                      style: TextStyle(color: Colors.white24, fontSize: 11.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.onTap,
    this.tint,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: (tint ?? Colors.white).withOpacity(tint == null ? 0.05 : 0.08),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final VisualizerStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? scheme.primary.withOpacity(0.14)
                : Colors.white.withOpacity(0.04),
            border: Border.all(
              color: selected
                  ? scheme.primary.withOpacity(0.7)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                style.icon,
                color: selected ? scheme.primary : Colors.white70,
                size: 26,
              ),
              const Spacer(),
              Text(
                style.label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                style.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
