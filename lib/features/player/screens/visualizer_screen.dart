import 'package:flutter/material.dart';
import '../../visualizers/visualizer_style.dart';
import '../../visualizers/visualizer_view.dart';
import '../player_controller.dart';
import 'fullscreen_visualizer_screen.dart';

class VisualizerScreen extends StatelessWidget {
  const VisualizerScreen({super.key, required this.controller});

  final PlayerController controller;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () => _openFullscreen(context),
                  child: VisualizerView(
                    data: controller.data,
                    config: controller.config,
                    theme: controller.theme,
                    style: controller.style,
                    onTick: controller.tick,
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF080810),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.music_note_rounded,
                              size: 20, color: Colors.white45),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.track?.title ?? 'No track loaded',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Import another track',
                            icon: const Icon(Icons.folder_open_rounded),
                            onPressed: controller.isLoading ? null : controller.importAudio,
                          ),
                          IconButton(
                            tooltip: 'Fullscreen',
                            icon: const Icon(Icons.fullscreen_rounded),
                            onPressed: controller.hasTrack
                                ? () => _openFullscreen(context)
                                : null,
                          ),
                          IconButton(
                            tooltip: 'Settings',
                            icon: const Icon(Icons.tune_rounded),
                            onPressed: () => showSettingsSheet(context, controller),
                          ),
                        ],
                      ),

                      StreamBuilder<Duration>(
                        stream: controller.engine.positionStream,
                        builder: (context, snapshot) {
                          final pos = snapshot.data ?? Duration.zero;
                          final dur = controller.track?.duration ?? Duration.zero;
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: dur.inMilliseconds == 0
                                      ? 0
                                      : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0).toDouble(),
                                  onChanged: (v) {
                                    if (dur.inMilliseconds > 0) {
                                      controller.seek(Duration(
                                          milliseconds: (v * dur.inMilliseconds).round()));
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_fmt(pos),
                                        style: const TextStyle(color: Colors.white35, fontSize: 11)),
                                    Text(_fmt(dur),
                                        style: const TextStyle(color: Colors.white35, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      Row(
                        children: [
                          _RoundButton(
                            icon: Icons.stop_rounded,
                            onPressed: controller.hasTrack ? controller.stop : null,
                          ),
                          const Spacer(),
                          _RoundButton(
                            icon: Icons.replay_10_rounded,
                            small: true,
                            onPressed: controller.hasTrack
                                ? () => controller.seek(
                                    controller.engine.position - const Duration(seconds: 10))
                                : null,
                          ),
                          const SizedBox(width: 14),
                          StreamBuilder<bool>(
                            stream: controller.engine.playingStream,
                            initialData: false,
                            builder: (context, snapshot) {
                              final playing = snapshot.data ?? false;
                              return GestureDetector(
                                onTap: playing ? controller.pause : controller.play,
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.tertiary,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.55),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 14),
                          _RoundButton(
                            icon: Icons.forward_10_rounded,
                            small: true,
                            onPressed: controller.hasTrack
                                ? () => controller.seek(
                                    controller.engine.position + const Duration(seconds: 10))
                                : null,
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final s in VisualizerStyle.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(s.label),
                                  selected: controller.style == s,
                                  showCheckmark: false,
                                  onSelected: (_) => controller.selectStyle(s),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: FullscreenVisualizerScreen(controller: controller),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed, this.small = false});

  final IconData icon;
  final VoidCallback? onPressed;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 44.0 : 50.0;
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: onPressed == null ? 0.02 : 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, size: small ? 20 : 24,
            color: onPressed == null ? Colors.white20 : Colors.white70),
      ),
    );
  }
}
