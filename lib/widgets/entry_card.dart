import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import 'package:intl/intl.dart';

class EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback? onTap;
  final String? searchQuery;

  const EntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).colorScheme.surface, // keep card bg dark
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and date
              Row(
                children: [
                  Expanded(
                    child: _buildHighlightedText(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (entry.isFavorite)
                    Icon(
                      Icons.favorite,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Date and duration
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm').format(entry.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.mic,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(entry.duration),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Summary or transcription preview
              if (entry.summary?.isNotEmpty == true) ...[
                _buildHighlightedText(
                  entry.summary!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 3,
                ),
              ] else if (entry.transcription?.isNotEmpty == true) ...[
                _buildHighlightedText(
                  entry.transcription!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 3,
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Status indicators
              Row(
                children: [
                  if (entry.transcription?.isNotEmpty == true) ...[
                    Icon(
                      Icons.text_fields,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Transcribed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (entry.summary?.isNotEmpty == true) ...[
                    Icon(
                      Icons.summarize,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Summarized',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text, {
    TextStyle? style,
    int? maxLines,
  }) {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    final query = searchQuery!.toLowerCase();
    final lowerText = text.toLowerCase();
    
    if (!lowerText.contains(query)) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    final spans = <TextSpan>[];
    int start = 0;
    
    while (start < text.length) {
      final index = lowerText.indexOf(query, start);
      
      if (index == -1) {
        // No more matches, add the rest of the text
        spans.add(TextSpan(
          text: text.substring(start),
          style: style,
        ));
        break;
      }
      
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }
      
      // Add the highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style?.copyWith(
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes == 0) {
      return '${remainingSeconds}s';
    } else if (minutes < 60) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
}
