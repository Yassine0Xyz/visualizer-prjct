class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.title,
    required this.filePath,
    this.artist,
    this.duration = Duration.zero,
  });

  final String id;
  final String title;
  final String? artist;
  final String filePath;
  final Duration duration;

  String get displayName => artist == null || artist!.isEmpty ? title : '$artist – $title';
}
