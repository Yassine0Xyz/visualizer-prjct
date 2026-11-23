import 'package:just_audio/just_audio.dart';

class AudioEngine {
  final AudioPlayer _player = AudioPlayer(
    androidAudioOffloadPreferences: const AndroidAudioOffloadPreferences(
      audioOffloadMode: AndroidAudioOffloadMode.disabled,
    ),
  );

  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get playing => _player.playing;
  Duration get position => _player.position;

  Future<Duration?> loadFile(String path) => _player.setFilePath(path);
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> dispose() => _player.dispose();
}
