import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/firebase_service.dart';
import '../services/refresh_manager.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/empty_state.dart';
import 'entry_details_screen.dart';
import '../config/theme.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> with RefreshableScreen {
  List<JournalEntry> _favorites = [];
  bool _loading = true;
  String? _error;
  bool _hasChanges = false; // Track if changes were made

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // Implement the RefreshableScreen mixin method
  @override
  void onRefresh() {
    debugPrint('🔄 FavoriteScreen: Global refresh triggered');
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

  // Navigate to the entry details screen
  Future<void> _navigateToEntryDetailsScreen(BuildContext context, JournalEntry entry) async {
    debugPrint('🧭 FavoriteScreen: Navigating to EntryDetailsScreen for entry ${entry.id}');
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EntryDetailsScreen(
          entry: entry,
          onEntryUpdated: (updatedEntry) {
            debugPrint('📝 FavoriteScreen: Entry updated callback received');
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: AppTheme.mediumAnimationDuration,
      ),
    );
    
    debugPrint('🔙 FavoriteScreen: Returned from EntryDetailsScreen with result: $result');
    // If result is true, reload favorites and notify parent of changes
    if (result == true) {
      debugPrint('🔄 FavoriteScreen: Result is true, reloading favorites...');
      await _loadFavorites();
      // Mark that changes were made so parent can reload too
      _hasChanges = true;
    } else {
      debugPrint('ℹ️ FavoriteScreen: Result is not true, no reload needed');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            debugPrint('🔙 FavoriteScreen: Manual back pressed, hasChanges: $_hasChanges');
            Navigator.of(context).pop(_hasChanges);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final entry = _favorites[index];
          return JournalEntryCard(
            entry: entry,
            onTap: () => _navigateToEntryDetailsScreen(context, entry),
            onFavoriteToggle: (isFavorite) async {
              debugPrint('⭐ FavoriteScreen: Favorite toggle triggered for ${entry.id} - isFavorite: $isFavorite');
              final updatedEntry = JournalEntry(
                id: entry.id,
                title: entry.title,
                date: entry.date,
                audioPath: entry.audioPath,
                transcription: entry.transcription,
                summary: entry.summary,
                suggestions: entry.suggestions,
                duration: entry.duration,
                notes: entry.notes,
                isFavorite: isFavorite,
              );
              try {
                debugPrint('💾 FavoriteScreen: Saving favorite status to Firestore...');
                await FirebaseService().saveJournalEntry(updatedEntry);
                debugPrint('✅ FavoriteScreen: Favorite status saved, refreshing all screens...');
                RefreshManager.refreshAfterFavoriteToggle();
                _hasChanges = true; // Mark that changes were made
              } catch (e) {
                debugPrint('❌ FavoriteScreen: Failed to save favorite status: $e');
              }
            },
          );
        },
      ),
    );
  }
}
