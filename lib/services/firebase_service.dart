import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';

class FirebaseService {

	Future<List<JournalEntry>> loadJournalEntries() async {
		debugPrint('🔍 FirebaseService: Starting to load journal entries');
		final user = _auth.currentUser;
		if (user == null) {
			debugPrint('❌ FirebaseService: No user signed in');
			throw Exception('No user signed in');
		}
		debugPrint('👤 FirebaseService: Loading entries for user ${user.uid}');

		final query = await _firestore
				.collection('journal_entries')
				.where('userId', isEqualTo: user.uid)
				.orderBy('date', descending: true)
				.get();

		debugPrint('📄 FirebaseService: Found ${query.docs.length} documents in Firestore');
		final entries = query.docs.map((doc) {
			final data = doc.data();
			return JournalEntry.fromMap(data);
		}).toList();
		
		debugPrint('✅ FirebaseService: Successfully converted ${entries.length} entries');
		return entries;
	}
	final _firestore = FirebaseFirestore.instance;
	final _auth = FirebaseAuth.instance;

		Future<void> saveJournalEntry(JournalEntry entry) async {
			try {
				debugPrint('💾 FirebaseService: Starting to save journal entry ${entry.id}');
				final user = _auth.currentUser;
				if (user == null) {
					debugPrint('❌ FirebaseService: No user signed in for save operation');
					throw Exception('No user signed in');
				}
				debugPrint('👤 FirebaseService: Saving entry for user ${user.uid}');

				   final data = entry.toMap();
				   data['userId'] = user.uid;
				   debugPrint('📝 FirebaseService: Writing to Firestore collection journal_entries/${entry.id}');
				   await _firestore.collection('journal_entries').doc(entry.id).set(data);
				   debugPrint('✅ FirebaseService: Successfully saved journal entry ${entry.id}');
			} catch (e, stack) {
				debugPrint('❌ FirebaseService: Failed to save journal entry: $e');
				debugPrint('📍 FirebaseService: Stack trace: $stack');
				print('[ERROR] Failed to save journal entry: $e');
				print(stack);
				rethrow;
			}
		}
	Future<void> deleteJournalEntry(String entryId) async {
		try {
			debugPrint('🗑️ FirebaseService: Starting to delete journal entry $entryId');
			final user = _auth.currentUser;
			if (user == null) {
				debugPrint('❌ FirebaseService: No user signed in for delete operation');
				throw Exception('No user signed in');
			}
			debugPrint('👤 FirebaseService: Deleting entry for user ${user.uid}');
			debugPrint('📝 FirebaseService: Deleting from Firestore collection journal_entries/$entryId');
			await _firestore.collection('journal_entries').doc(entryId).delete();
			debugPrint('✅ FirebaseService: Successfully deleted journal entry $entryId');
		} catch (e, stack) {
			debugPrint('❌ FirebaseService: Failed to delete journal entry: $e');
			debugPrint('📍 FirebaseService: Stack trace: $stack');
			print('[ERROR] Failed to delete journal entry: $e');
			print(stack);
			rethrow;
		}
	}
}
