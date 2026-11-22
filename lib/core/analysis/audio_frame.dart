import 'dart:typed_data';

/// One analysis snapshot of the audio at a point in time.
///
/// This is the data model shared by every visualizer. Renderers depend only
/// on this class (plus config/theme), never on playback or analysis code.
class AudioFrame {
  const AudioFrame({
    required this.timeMs,
    required this.bands,
    required this.bass,
    required this.mid,
    required this.high,
    required this.energy,
  });

  /// Position in the track, in milliseconds.
  final double timeMs;

  /// Log-spaced frequency band magnitudes, normalized to 0..1.
  final Float32List bands;

  /// 30–250 Hz.
  final double bass;

  /// 250 Hz–4 kHz.
  final double mid;

  /// 4 kHz–Nyquist.
  final double high;

  /// Overall loudness 0..1.
  final double energy;

  static const int bandCount = 48;
}
