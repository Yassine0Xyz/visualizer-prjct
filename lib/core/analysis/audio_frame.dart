import 'dart:typed_data';

class AudioFrame {
  const AudioFrame({
    required this.timeMs,
    required this.bands,
    required this.bass,
    required this.mid,
    required this.high,
    required this.energy,
    required this.bassEnergy,
    required this.midEnergy,
    required this.highEnergy,
    this.waveformLeft,
    this.waveformRight,
  });

  final double timeMs;
  final Float32List bands;
  final double bass;
  final double mid;
  final double high;
  final double energy;
  final double bassEnergy;
  final double midEnergy;
  final double highEnergy;
  /// Downsampled waveform snapshots retained for time-domain visualizers.
  final Float32List? waveformLeft;
  final Float32List? waveformRight;

  static const int bandCount = 64;
}
