import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';

class CalendarScreen extends StatefulWidget {
  final List<JournalEntry> entries;
  final Function(JournalEntry entry)? onEntryTap;

  const CalendarScreen({
    Key? key, 
    required this.entries,
    this.onEntryTap,
  }) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Map to store entries by day
  late Map<DateTime, List<JournalEntry>> _entriesByDay;

  @override
  void initState() {
    super.initState();
    _initEntriesByDay();
  }

  void _initEntriesByDay() {
    _entriesByDay = {};
    for (var entry in widget.entries) {
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
    final selectedDayEntries = _getEntriesForDay(_selectedDay);
    // Sort entries by time (newest first for the selected day)
    selectedDayEntries.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
  // AppBar removed to avoid double app bar
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
            headerStyle: const HeaderStyle(
              formatButtonTextStyle: TextStyle(fontSize: 14),
              titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }
} 