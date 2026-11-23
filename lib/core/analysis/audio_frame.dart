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

  static const int bandCount = 64;
}
