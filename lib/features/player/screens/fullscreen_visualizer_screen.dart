import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../visualizers/visualizer_view.dart';
import '../player_controller.dart';

class FullscreenVisualizerScreen extends StatefulWidget {
  const FullscreenVisualizerScreen({super.key, required this.controller});

  final PlayerController controller;

  @override
  State<FullscreenVisualizerScreen> createState() =>
      _FullscreenVisualizerScreenState();
}

class _FullscreenVisualizerScreenState extends State<FullscreenVisualizerScreen> {
  bool _overlayVisible = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _overlayVisible = !_overlayVisible),
        child: Stack(
          fit: StackFit.expand,
          children: [
            VisualizerView(
              data: controller.data,
              config: controller.config,
              theme: controller.theme,
              style: controller.style,
              onTick: controller.tick,
            ),
            AnimatedOpacity(
              opacity: _overlayVisible ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_overlayVisible,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.fullscreen_exit_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.track?.title ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StreamBuilder<bool>(
                            stream: controller.engine.playingStream,
                            initialData: false,
                            builder: (context, snapshot) {
                              final playing = snapshot.data ?? false;
                              return IconButton(
                                iconSize: 32,
                                icon: Icon(playing
                                    ? Icons.pause_circle_outline_rounded
                                    : Icons.play_circle_outline_rounded),
                                onPressed: playing ? controller.pause : controller.play,
                              );
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      Center(
                        child: Text(
                          'Double-tap screen or tap ✕ to exit fullscreen',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.30),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
