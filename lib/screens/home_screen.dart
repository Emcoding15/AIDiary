import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../config/theme.dart';
import '../screens/record_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<JournalEntry> entries;
  final Function(JournalEntry entry)? onEntryTap;

  const HomeScreen({
    Key? key, 
    this.entries = const [], 
    this.onEntryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _buildEmptyState(context);
    }

    // Group entries by date
    final Map<String, List<JournalEntry>> entriesByDate = {};
    for (var entry in entries) {
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
      appBar: AppBar(
        title: const Text('Audio Journal'),
        elevation: 0,
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Journal',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  // Stats card
                  if (entries.isNotEmpty) _buildStatsCard(context),
                ],
              ),
            ),
          ),
          
          // Recent entries header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Recent Entries',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          
          // Entries list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dateString = sortedDates[index];
                final date = DateTime.parse(dateString);
                final entriesForDate = entriesByDate[dateString]!;
                
                // Sort entries for this date by time (newest first)
                entriesForDate.sort((a, b) => b.date.compareTo(a.date));
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded, 
                              size: 14, 
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateHeader(date),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Entries for this date
                    ...entriesForDate.map((entry) => _buildEntryCard(context, entry)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Journal'),
        elevation: 0,
      ),
      body: Center(
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
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const RecordScreen(),
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
              },
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Start Recording'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsCard(BuildContext context) {
    final entriesThisWeek = entries.where((entry) {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
      return entry.date.isAfter(weekStart);
    }).length;
    
    final totalMinutes = entries.fold<int>(0, (sum, entry) {
      // This is a placeholder. In a real app, you'd get the actual duration
      return sum + 5; // Assuming 5 minutes per entry for demonstration
    });
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                context,
                '${entries.length}',
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
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEntryCard(BuildContext context, JournalEntry entry) {
    final hasTranscription = entry.transcription != null && entry.transcription!.isNotEmpty;
    final hasSummary = entry.summary != null && entry.summary!.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Hero(
        tag: 'entry_${entry.id}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (onEntryTap != null) {
                onEntryTap!(entry);
              }
            },
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            child: Ink(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                boxShadow: AppTheme.lightShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Entry icon with status indicator
                        Stack(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.mic_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            if (hasTranscription)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.text_fields,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Title and time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('h:mm a').format(entry.date),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Summary if available
                  if (hasSummary) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.summary!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            if (onEntryTap != null) {
                              onEntryTap!(entry);
                            }
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('Play'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            if (onEntryTap != null) {
                              onEntryTap!(entry);
                            }
                          },
                          icon: const Icon(Icons.more_horiz_rounded, size: 20),
                          label: const Text('Details'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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