import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import '../models/journal_entry.dart';
import '../services/firebase_service.dart';
import '../services/refresh_manager.dart';
import '../config/theme.dart';
import '../utils/snackbar_utils.dart';

import 'record_screen.dart';
import 'entry_details_screen.dart';

import '../widgets/journal_entry_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/record_entry_fab.dart';
import '../widgets/search_widget.dart';

class HomeScreen extends StatefulWidget {
  final Function(JournalEntry entry)? onEntryTap;
  final Function(JournalEntry entry)? onEntryAdded;

  const HomeScreen({
    Key? key,
    this.onEntryTap,
    this.onEntryAdded,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, RefreshableScreen {
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;
  late Animation<Color?> _color3;

  List<JournalEntry> _entries = [];
  bool _loading = true;
  bool _isLoadingInProgress = false; // Add guard to prevent concurrent loads
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 HomeScreen: initState() called');
    // Load data immediately for the home screen since it's the default screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadEntries();
    });

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOutCubic),
    );
    _color1 = ColorTween(
      begin: const Color(0xFF43E97B), // Green
      end: const Color(0xFF38F9D7), // Aqua
    ).animate(_gradientController);
    _color2 = ColorTween(
      begin: const Color(0xFF38F9D7), // Aqua
      end: const Color(0xFF1E3C72), // Deep blue
    ).animate(_gradientController);
    _color3 = ColorTween(
      begin: const Color(0xFF1E3C72), // Deep blue
      end: const Color(0xFF43E97B), // Green
    ).animate(_gradientController);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  // Implement the RefreshableScreen mixin method
  @override
  void onRefresh() {
    debugPrint('🔄 HomeScreen: Global refresh triggered');
    loadEntries();
  }

  Future<void> loadEntries() async {
    // Prevent concurrent loading
    if (_isLoadingInProgress) {
      debugPrint('⏸️ HomeScreen: Load already in progress, skipping duplicate call');
      return;
    }
    
    debugPrint('🔄 HomeScreen: Starting to load entries from Firestore');
    _isLoadingInProgress = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await FirebaseService().loadJournalEntries();
      debugPrint('✅ HomeScreen: Successfully loaded ${entries.length} entries from Firestore');
      setState(() {
        _entries = entries;
        _loading = false;
      });
      debugPrint('🔄 HomeScreen: UI updated with ${entries.length} entries');
    } catch (e) {
      debugPrint('❌ HomeScreen: Failed to load entries: $e');
      setState(() {
        _error = 'Failed to load entries.';
        _loading = false;
      });
    } finally {
      _isLoadingInProgress = false;
      debugPrint('🏁 HomeScreen: Load operation completed');
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
        body: Center(
          child: Text(
            'Failed to load entries.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return const EmptyState();
    }

    // Group entries by date
    final Map<String, List<JournalEntry>> entriesByDate = {};
    for (var entry in _entries) {
      final dateString = DateFormat('yyyy-MM-dd').format(entry.date);
      if (!entriesByDate.containsKey(dateString)) {
        entriesByDate[dateString] = [];
      }
      entriesByDate[dateString]!.add(entry);
    }

    // Sort dates (newest first)
    final sortedDates = entriesByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final entriesThisWeek = _entries.where((entry) {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
      return entry.date.isAfter(weekStart);
    }).length;
    final totalSeconds = _entries.fold<int>(0, (sum, entry) => sum + (entry.duration));
    final totalMinutes = (totalSeconds / 60).ceil();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Welcome header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Journal',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 36,
                      letterSpacing: 0.5,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Color(0xFF11998e).withOpacity(0.6), // Teal echo
                          blurRadius: 0,
                          offset: Offset(3, 3),
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: Offset(4, 4),
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 8,
                          offset: Offset(8, 8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search widget
                  const SearchWidget(),
                  const SizedBox(height: 8),
                  if (_entries.isNotEmpty)
                    StatsCard(
                      totalEntries: _entries.length,
                      entriesThisWeek: entriesThisWeek,
                      totalMinutes: totalMinutes,
                    ),
                ],
              ),
            ),
          ),
          // List of journal entries grouped by date
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final date = sortedDates[index];
                final entriesForDate = entriesByDate[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        _formatDateHeader(DateTime.parse(date)),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    ...entriesForDate.map((entry) => _buildEntryCard(context, entry)).toList(),
                  ],
                );
              },
              childCount: sortedDates.length,
            ),
          ),
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  
  
  Widget _buildEntryCard(BuildContext context, JournalEntry entry) {
    return JournalEntryCard(
      entry: entry,
      onTap: widget.onEntryTap != null ? () {
        debugPrint('👆 HomeScreen: Entry tapped - ${entry.title} (${entry.id})');
        widget.onEntryTap!(entry);
      } : null,
      onDeleted: () async {
        debugPrint('🗑️ HomeScreen: Entry deleted callback triggered for ${entry.id}');
        // Refresh handled by global refresh manager in EntryDetailsScreen
        if (context.mounted) {
          SnackBarUtils.showEntryDeleted(context);
        }
      },
      onFavoriteToggle: (isFavorite) async {
        debugPrint('⭐ HomeScreen: Favorite toggle triggered for ${entry.id} - isFavorite: $isFavorite');
        final updatedEntry = JournalEntry(
          id: entry.id,
          title: entry.title,
          date: entry.date,
          audioPath: entry.audioPath,
          transcription: entry.transcription,
          summary: entry.summary,
          suggestions: entry.suggestions,
          duration: entry.duration,
          notes: entry.notes, // Preserve notes
          isFavorite: isFavorite,
        );
        try {
          debugPrint('💾 HomeScreen: Saving favorite status to Firestore...');
          await FirebaseService().saveJournalEntry(updatedEntry);
          debugPrint('✅ HomeScreen: Favorite status saved, refreshing all screens...');
          RefreshManager.refreshAfterFavoriteToggle();
        } catch (e) {
          debugPrint('❌ HomeScreen: Failed to save favorite status: $e');
        }
      },
    );
  }
  
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
      return 'Today';
    } else if (dateOnly.isAtSameMomentAs(DateTime(yesterday.year, yesterday.month, yesterday.day))) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('EEEE, MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
