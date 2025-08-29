import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/firebase_service.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/empty_state.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<JournalEntry> _favorites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await FirebaseService().loadJournalEntries();
      setState(() {
        _favorites = entries.where((e) => e.isFavorite).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load favorites.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }
    if (_favorites.isEmpty) {
      return const EmptyState(message: 'No favorite entries yet.');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Entries'),
      ),
      body: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final entry = _favorites[index];
          return JournalEntryCard(
            entry: entry,
            onFavoriteToggle: (isFavorite) async {
              final updatedEntry = JournalEntry(
                id: entry.id,
                title: entry.title,
                date: entry.date,
                audioPath: entry.audioPath,
                transcription: entry.transcription,
                summary: entry.summary,
                suggestions: entry.suggestions,
                duration: entry.duration,
                isFavorite: isFavorite,
              );
              await FirebaseService().saveJournalEntry(updatedEntry);
              await _loadFavorites();
            },
          );
        },
      ),
    );
  }
}
