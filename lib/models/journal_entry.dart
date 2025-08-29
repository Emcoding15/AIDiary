class JournalEntry {
  final String id;
  final String title;
  final DateTime date;
  final String? audioPath;
  final String? transcription;
  final String? summary;
  final String? suggestions;
  final int duration; // duration in seconds
  final bool isFavorite;

  JournalEntry({
    required this.id,
    required this.title,
    required this.date,
    this.audioPath,
    this.transcription,
    this.summary,
    this.suggestions,
    required this.duration,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'audioPath': audioPath,
      'transcription': transcription,
      'summary': summary,
      'suggestions': suggestions,
      'duration': duration,
      'isFavorite': isFavorite,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      audioPath: map['audioPath'] as String?,
      transcription: map['transcription'] as String?,
      summary: map['summary'] as String?,
      suggestions: map['suggestions'] as String?,
      duration: map['duration'] is int ? map['duration'] as int : int.tryParse(map['duration'].toString()) ?? 0,
      isFavorite: map['isFavorite'] == true,
    );
  }
}