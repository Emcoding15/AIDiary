class JournalEntry {
  final String id;
  final String title;
  final DateTime date;
  final String? audioPath;
  final String? transcription;
  final String? summary;

  JournalEntry({
    required this.id,
    required this.title,
    required this.date,
    this.audioPath,
    this.transcription,
    this.summary,
  });
} 