import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';

class EntryHeader extends StatelessWidget {
  final JournalEntry entry;
  const EntryHeader({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(entry.date);
    final formattedTime = DateFormat('h:mm a').format(entry.date);
    return Hero(
      tag: 'entry_${entry.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF26C6DA), // Slightly darker aqua (top)
                Color(0xFF13BBAF), // Rich aqua (middle)
                Color(0xFF11998e), // Deep aqua/teal (bottom)
              ],
              stops: [0.0, 0.6, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            boxShadow: AppTheme.lightShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white, // soft light gray
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.32), // darker shadow
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7), // Slightly less bright
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7), // Slightly less bright
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
