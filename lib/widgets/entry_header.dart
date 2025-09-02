import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/firebase_service.dart';
import '../services/refresh_manager.dart';

class EntryHeader extends StatefulWidget {
  final JournalEntry entry;
  final Function(JournalEntry updatedEntry)? onEntryUpdated;
  
  const EntryHeader({
    Key? key, 
    required this.entry,
    this.onEntryUpdated,
  }) : super(key: key);

  @override
  State<EntryHeader> createState() => _EntryHeaderState();
}

class _EntryHeaderState extends State<EntryHeader> {
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  final FirebaseService _firebaseService = FirebaseService();
  late JournalEntry _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _titleController = TextEditingController(text: _currentEntry.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    try {
      // Create updated entry with new title
      final updatedEntry = JournalEntry(
        id: widget.entry.id,
        title: newTitle,
        date: widget.entry.date,
        transcription: widget.entry.transcription,
        summary: widget.entry.summary,
        suggestions: widget.entry.suggestions,
        audioPath: widget.entry.audioPath,
        notes: widget.entry.notes,
        duration: widget.entry.duration,
        isFavorite: widget.entry.isFavorite,
      );

      await _firebaseService.saveJournalEntry(updatedEntry);
      
      setState(() {
        _currentEntry = updatedEntry;
        _isEditingTitle = false;
      });

      // Notify parent about the update
      widget.onEntryUpdated?.call(updatedEntry);

      // Trigger global refresh
      RefreshManager.refreshAllScreens();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating title: $e')),
        );
      }
    }
  }

  void _cancelEdit() {
    _titleController.text = _currentEntry.title;
    setState(() {
      _isEditingTitle = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_currentEntry.date);
    final formattedTime = DateFormat('h:mm a').format(_currentEntry.date);
    return Hero(
      tag: 'entry_${_currentEntry.id}',
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
              // Title section with edit functionality
              _isEditingTitle ? _buildEditingTitle() : _buildDisplayTitle(),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayTitle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditingTitle = true;
        });
      },
      child: Row(
        children: [
          Expanded(
            child: Text(
              _currentEntry.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.32),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.edit,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEditingTitle() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
            maxLines: 1,
            autofocus: true,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _saveTitle,
          icon: Icon(
            Icons.check,
            color: Colors.green[100],
            size: 24,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            minimumSize: Size(36, 36),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _cancelEdit,
          icon: Icon(
            Icons.close,
            color: Colors.red[100],
            size: 24,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            minimumSize: Size(36, 36),
          ),
        ),
      ],
    );
  }
}
