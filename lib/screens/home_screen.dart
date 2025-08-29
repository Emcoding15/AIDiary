import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import '../models/journal_entry.dart';
import '../services/firebase_service.dart';
import '../config/theme.dart';

import 'record_screen.dart';
import 'entry_details_screen.dart';
import '../widgets/journal_entry_card.dart';

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

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;
  late Animation<Color?> _color3;

  List<JournalEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadEntries();

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

  Future<void> loadEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await FirebaseService().loadJournalEntries();
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load entries.';
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
      return _buildEmptyState(context);
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

    return Scaffold(
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.lightShadow,
          borderRadius: BorderRadius.circular(32),
        ),
        child: FloatingActionButton(
          heroTag: 'home_fab',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => RecordScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
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
            // Auto-refresh entries if a new entry was added or deleted
            if (result != null && result is JournalEntry) {
              await loadEntries();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Journal entry saved successfully!'),
                    backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } else if (result == true) {
              // Entry was deleted
              await loadEntries();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Journal entry deleted.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
          elevation: 0,
          child: Icon(
            Icons.mic_rounded,
            color: Color(0xFF1A2B2E),
            size: 24,
          ),
        ),
      ),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_entries.isNotEmpty) _buildStatsCard(context),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none_rounded,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No journal entries yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the mic button to record your first entry',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => RecordScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
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
              // Auto-refresh entries if a new entry was added
              if (result != null && result is JournalEntry) {
                await loadEntries();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Journal entry saved successfully!'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Start Recording'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsCard(BuildContext context) {
    final entriesThisWeek = _entries.where((entry) {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
      return entry.date.isAfter(weekStart);
    }).length;

    final totalSeconds = _entries.fold<int>(0, (sum, entry) => sum + (entry.duration ?? 0));
    final totalMinutes = (totalSeconds / 60).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF38F9D7), // Aqua (top)
            Color(0xFF1DE9B6), // Bright teal (middle)
            Color(0xFF13BBAF), // Subtle medium teal (bottom)
          ],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  margin: const EdgeInsets.only(top: 32), // lower the wave
                  height: 185,
                width: double.infinity,
                child: WaveWidget(
                  config: CustomConfig(
                    gradients: [
                      [
                        Color(0xFF38F9D7), // Aqua
                        Color(0xFF1DE9B6), // Bright teal
                        Color(0xFF13BBAF), // Medium teal
                      ],
                      [
                        Color(0xFF13BBAF), // Medium teal
                        Color(0xFF1DE9B6), // Bright teal
                        Color(0xFF38F9D7), // Aqua
                      ],
                    ],
                    durations: [4500, 19440],
                    heightPercentages: [0.22, 0.25],
                    blur: MaskFilter.blur(BlurStyle.solid, 2),
                    gradientBegin: Alignment.centerLeft,
                    gradientEnd: Alignment.centerRight,
                  ),
                  waveAmplitude: 3,
                  backgroundColor: Colors.transparent,
                  size: const Size(double.infinity, double.infinity),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Color(0xFF1A2B2E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatItem(
                        context,
                        '${_entries.length}',
                        'Total\nEntries',
                        Icons.list_alt_rounded,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        context,
                        '$entriesThisWeek',
                        'Entries\nThis Week',
                        Icons.calendar_today_rounded,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        context,
                        '$totalMinutes',
                        'Total\nMinutes',
                        Icons.access_time_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Color(0xFF1A2B2E),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
                  color: Color(0xFF1A2B2E),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEntryCard(BuildContext context, JournalEntry entry) {
    return JournalEntryCard(
      entry: entry,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EntryDetailsScreen(entry: entry),
          ),
        );
        if (result == true) {
          await loadEntries();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Journal entry deleted.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
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
