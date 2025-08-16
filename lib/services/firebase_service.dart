import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

class FirebaseService {

	Future<List<JournalEntry>> loadJournalEntries() async {
		final user = _auth.currentUser;
		if (user == null) throw Exception('No user signed in');

		final query = await _firestore
				.collection('journal_entries')
				.where('userId', isEqualTo: user.uid)
				.orderBy('date', descending: true)
				.get();

		return query.docs.map((doc) {
			final data = doc.data();
				return JournalEntry(
					id: data['id'] ?? doc.id,
					title: data['title'] ?? '',
					date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
					audioPath: data['audioPath'],
					transcription: data['transcription'],
					summary: data['summary'],
					duration: data['duration'] ?? 0,
				);
		}).toList();
	}
	final _firestore = FirebaseFirestore.instance;
	final _auth = FirebaseAuth.instance;

		Future<void> saveJournalEntry(JournalEntry entry) async {
			try {
				final user = _auth.currentUser;
				if (user == null) throw Exception('No user signed in');

				final data = {
					'id': entry.id,
					'userId': user.uid,
					'title': entry.title,
					'date': entry.date.toIso8601String(),
					'audioPath': entry.audioPath,
					'transcription': entry.transcription,
					'summary': entry.summary,
					'duration': entry.duration,
				};
				await _firestore.collection('journal_entries').doc(entry.id).set(data);
			} catch (e, stack) {
				print('[ERROR] Failed to save journal entry: $e');
				print(stack);
				rethrow;
			}
		}
}
