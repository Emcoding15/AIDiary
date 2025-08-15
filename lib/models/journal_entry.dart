class JournalEntry {
  final String id;
  final String title;
  final DateTime date;
  final String? audioPath;
  final String? transcription;
  final String? summary;
  final int duration; // duration in seconds

  JournalEntry({
    required this.id,
    required this.title,
    required this.date,
    this.audioPath,
    this.transcription,
    this.summary,
    required this.duration,
  });
}