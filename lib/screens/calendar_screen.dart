import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/firebase_service.dart';
import '../services/refresh_manager.dart';
import 'record_screen.dart';
import '../config/theme.dart';

class CalendarScreen extends StatefulWidget {
  final Function(JournalEntry entry)? onEntryTap;

  const CalendarScreen({
    Key? key,
    this.onEntryTap,
  }) : super(key: key);

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}


class CalendarScreenState extends State<CalendarScreen> with RefreshableScreen {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<JournalEntry> _entries = [];
  Map<DateTime, List<JournalEntry>> _entriesByDay = {};
  bool _loading = true;
  bool _isLoadingInProgress = false; // Add guard to prevent concurrent loads
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('📅 CalendarScreen: initState() called');
    // Load data immediately when calendar screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadEntries();
    });
  }

  // Implement the RefreshableScreen mixin method
  @override
  void onRefresh() {
    debugPrint('🔄 CalendarScreen: Global refresh triggered');
    loadEntries();
  }

  Future<void> loadEntries() async {
    // Prevent concurrent loading
    if (_isLoadingInProgress) {
      debugPrint('⏸️ CalendarScreen: Load already in progress, skipping duplicate call');
      return;
    }
    
    debugPrint('🔄 CalendarScreen: Starting to load entries from Firestore');
    _isLoadingInProgress = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await FirebaseService().loadJournalEntries();
      debugPrint('✅ CalendarScreen: Successfully loaded ${entries.length} entries from Firestore');
      setState(() {
        _entries = entries;
        _initEntriesByDay();
        _loading = false;
      });
      debugPrint('🔄 CalendarScreen: UI updated with ${entries.length} entries');
    } catch (e) {
      debugPrint('❌ CalendarScreen: Failed to load entries: $e');
      setState(() {
        _error = 'Failed to load entries.';
        _loading = false;
      });
    } finally {
      _isLoadingInProgress = false;
      debugPrint('🏁 CalendarScreen: Load operation completed');
    }
  }

  void _initEntriesByDay() {
    _entriesByDay = {};
    for (var entry in _entries) {
      final date = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      if (_entriesByDay[date] == null) {
        _entriesByDay[date] = [];
      }
      _entriesByDay[date]!.add(entry);
    }
  }

  List<JournalEntry> _getEntriesForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _entriesByDay[date] ?? [];
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
        body: Center(child: Text('Failed to load entries.')),
      );
    }
    final selectedDayEntries = _getEntriesForDay(_selectedDay);
    // Sort entries by time (newest first for the selected day)
    selectedDayEntries.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              return _getEntriesForDay(day);
            },
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonTextStyle: TextStyle(fontSize: 14, color: Colors.white),
              titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Entries for ${DateFormat('MMMM d, y').format(_selectedDay)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${selectedDayEntries.length} entries',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedDayEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No entries for ${DateFormat('MMMM d').format(_selectedDay)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: selectedDayEntries.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = selectedDayEntries[index];
                      return ListTile(
                        title: Text(
                          entry.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('h:mm a').format(entry.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (entry.summary != null && entry.summary!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                entry.summary!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              child: Icon(
                                Icons.mic,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            // Indicator for transcription status
                            if (entry.transcription != null && entry.transcription!.isNotEmpty)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(
                                    Icons.text_fields,
                                    size: 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        onTap: () {
                          if (widget.onEntryTap != null) {
                            widget.onEntryTap!(entry);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
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
          // New entry refresh is handled by global refresh manager in main.dart
        },
        elevation: 4,
        child: const Icon(Icons.mic_rounded),
      ),
    );
  }
} 