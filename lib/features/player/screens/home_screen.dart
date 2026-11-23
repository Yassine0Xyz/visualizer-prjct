import 'package:flutter/material.dart';
import '../../visualizers/visualizer_style.dart';
import '../player_controller.dart';
import 'visualizer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0818),
              Color(0xFF050508),
              Color(0xFF080C14),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [scheme.primary, scheme.tertiary],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withValues(alpha: 0.50),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.graphic_eq_rounded, size: 30),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Visualizer Lab',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    Text(
                                      'V2 · Premium Audio Reactive Visualizers',
                                      style: TextStyle(
                                        color: Colors.white45,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // Import Card
                          _GlassCard(
                            onTap: controller.isLoading ? null : controller.importAudio,
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [scheme.primary.withValues(alpha: 0.3), scheme.tertiary.withValues(alpha: 0.2)],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: controller.isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(18),
                                          child: CircularProgressIndicator(strokeWidth: 2.5),
                                        )
                                      : const Icon(Icons.upload_file_rounded, size: 30),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        controller.isLoading ? 'Analyzing...' : 'Import Audio',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        controller.isLoading
                                            ? controller.statusMessage
                                            : 'Pick a local track to start experimenting',
                                        style: const TextStyle(
                                          color: Colors.white45,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 16, color: Colors.white30),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

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
                                  const Icon(Icons.play_circle_fill_rounded, size: 44),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          controller.track!.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Continue Session',
                                          style: TextStyle(
                                            color: scheme.primary.withValues(alpha: 0.85),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 40),
                          Text(
                            '18 Visualizer Styles',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Each style has a unique identity — all driven by real FFT analysis.',
                            style: TextStyle(color: Colors.white35, fontSize: 12.5),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final s = VisualizerStyle.values[index];
                          return _StyleCard(
                            style: s,
                            selected: controller.style == s,
                            onTap: () {
                              controller.selectStyle(s);
                              if (controller.hasTrack) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => VisualizerScreen(controller: controller),
                                  ),
                                );
                              } else {
                                controller.importAudio();
                              }
                            },
                          );
                        },
                        childCount: VisualizerStyle.values.length,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: Text(
                          'Standalone experiment · no connection to any other project',
                          style: TextStyle(color: Colors.white18, fontSize: 11),
                        ),
                      ),
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
  const _GlassCard({required this.child, this.onTap, this.tint});

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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: (tint ?? Colors.white).withValues(alpha: tint == null ? 0.04 : 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.style, required this.selected, required this.onTap});

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
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                style.icon,
                color: selected ? scheme.primary : Colors.white60,
                size: 28,
              ),
              const Spacer(),
              Text(
                style.label,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                style.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white30, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
