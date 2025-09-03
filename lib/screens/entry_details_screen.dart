import '../widgets/suggestions_section.dart';
import '../widgets/summary_section.dart';
import '../widgets/transcription_section.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../models/journal_entry.dart';
import '../services/ai_service.dart';
import '../services/refresh_manager.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/audio_controls.dart';
import '../config/theme.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../widgets/entry_header.dart';
import '../widgets/notes_section.dart';
import '../utils/snackbar_utils.dart';

class EntryDetailsScreen extends StatefulWidget {
  final JournalEntry entry;
  final Function(JournalEntry updatedEntry)? onEntryUpdated;

  const EntryDetailsScreen({
    Key? key,
    required this.entry,
    this.onEntryUpdated,
  }) : super(key: key);

  @override
  State<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AIService _aiService = AIService();
  bool _isPlaying = false;
  bool _isPlayerReady = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double? _fileSize;
  
  bool _isTranscribing = false;
  bool _isGeneratingSummary = false;
  String? _transcription;
  String? _summary;
  String? _suggestions;
  String? _notes;
  final TextEditingController _notesController = TextEditingController();
  bool _isSavingNotes = false;
  
  // Auto-save functionality
  Timer? _autoSaveTimer;
  String _lastSavedNotes = '';
  bool _hasUnsavedChanges = false;
  bool _hasAutoSaved = false; // Track if auto-save has occurred
  
  // Animation controller for content transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Current entry state
  late JournalEntry _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _initAudioPlayer();
    _loadFileSize();
    _transcription = widget.entry.transcription;
    _summary = widget.entry.summary;
    _suggestions = widget.entry.suggestions;
    _notes = widget.entry.notes;
    _notesController.text = _notes ?? '';
    _lastSavedNotes = _notes ?? ''; // Initialize last saved state
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.mediumAnimationDuration,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
  }

  void _onEntryUpdated(JournalEntry updatedEntry) {
    setState(() {
      _currentEntry = updatedEntry;
    });
  }

  Future<void> _loadFileSize() async {
    final audioPath = widget.entry.audioPath;
    if (audioPath != null) {
      try {
        final file = File(audioPath);
        if (await file.exists()) {
          final int size = await file.length();
          if (mounted) {
            setState(() {
              _fileSize = size / 1024; // Convert to KB
            });
          }
        }
      } catch (e) {
        debugPrint('Error getting file size: $e');
      }
    }
  }

  Future<void> _initAudioPlayer() async {
    try {
      // Check if audio path exists
      final audioPath = widget.entry.audioPath;
      if (audioPath == null) {
        debugPrint('Audio path is null');
        return;
      }
      
      // Check if the file exists
      final file = File(audioPath);
      debugPrint('Attempting to play audio from: $audioPath');
      
      if (await file.exists()) {
        debugPrint('Audio file exists, initializing player');
        await _audioPlayer.setFilePath(audioPath);
        if (!mounted) return;
        
        setState(() {
          _isPlayerReady = true;
        });

        // Listen to player state changes
        _audioPlayer.playerStateStream.listen((state) async {
          if (!mounted) return;
          if (state.processingState == ProcessingState.completed) {
            await _audioPlayer.pause(); // Ensure player is paused
            await _audioPlayer.seek(Duration.zero);
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });
          } else if (state.playing != _isPlaying) {
            setState(() {
              _isPlaying = state.playing;
            });
          }
        });

        // Listen to duration changes
        _audioPlayer.durationStream.listen((newDuration) {
          if (!mounted) return;
          if (newDuration != null) {
            setState(() {
              _duration = newDuration;
            });
          }
        });

        // Listen to position changes
        _audioPlayer.positionStream.listen((newPosition) {
          if (!mounted) return;
          setState(() {
            _position = newPosition;
          });
        });
      } else {
        debugPrint('Audio file not found at path: $audioPath');
      }
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  Future<void> _playPause() async {
    if (!_isPlayerReady) return;
    
    try {
      if (_isPlaying) {
        debugPrint('Pausing audio');
        await _audioPlayer.pause();
      } else {
        final audioPath = widget.entry.audioPath;
        if (audioPath == null) return;
        
        debugPrint('Playing audio from: $audioPath');
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  String _formatFileSize(double kiloBytes) {
    if (kiloBytes < 1024) {
      return '${kiloBytes.toStringAsFixed(1)} KB';
    } else {
      final megaBytes = kiloBytes / 1024;
      return '${megaBytes.toStringAsFixed(2)} MB';
    }
  }

  // Auto-save functionality
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel(); // Cancel any existing timer
    
    // Only schedule auto-save if there are actual changes
    if (_notesController.text != _lastSavedNotes) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        if (_notesController.text != _lastSavedNotes && !_isSavingNotes) {
          _autoSaveNotes();
        }
      });
    } else {
      setState(() {
        _hasUnsavedChanges = false;
      });
    }
  }

  Future<void> _autoSaveNotes() async {
    if (_isSavingNotes) return; // Prevent concurrent saves
    
    debugPrint('🔄 EntryDetailsScreen: Auto-saving notes for entry ${widget.entry.id}');
    setState(() {
      _isSavingNotes = true;
    });
    
    final updatedEntry = JournalEntry(
      id: widget.entry.id,
      title: widget.entry.title,
      date: widget.entry.date,
      audioPath: widget.entry.audioPath,
      transcription: _transcription,
      summary: _summary,
      suggestions: _suggestions,
      duration: widget.entry.duration,
      notes: _notesController.text,
      isFavorite: widget.entry.isFavorite, // Preserve favorite status
    );
    
    try {
      debugPrint('💾 EntryDetailsScreen: Auto-saving notes to Firestore...');
      await FirebaseService().saveJournalEntry(updatedEntry);
      debugPrint('✅ EntryDetailsScreen: Notes auto-saved successfully to Firestore');
      
      _lastSavedNotes = _notesController.text;
      _hasAutoSaved = true; // Mark that auto-save has occurred
      
      // Update local state to reflect the saved data
      setState(() {
        _notes = _notesController.text;
        _hasUnsavedChanges = false;
      });
      
      widget.onEntryUpdated?.call(updatedEntry);
      
      // Refresh all screens after saving notes
      RefreshManager.refreshAfterNotesUpdate();
      
      // Show subtle feedback
      if (mounted) {
        SnackBarUtils.showInfo(context, 'Notes saved automatically');
      }
    } catch (e) {
      debugPrint('❌ EntryDetailsScreen: Failed to auto-save notes: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to auto-save notes: $e');
      }
    } finally {
      setState(() {
        _isSavingNotes = false;
      });
    }
  }

  @override
  void dispose() {
  _audioPlayer.dispose();
  _animationController.dispose();
  _notesController.dispose();
  _autoSaveTimer?.cancel(); // Cancel auto-save timer
  super.dispose();
  }



  Future<void> _transcribeAndSummarize() async {
  final audioPath = widget.entry.audioPath;
  if (audioPath == null) {
    SnackBarUtils.showError(context, 'No audio file available to transcribe and summarize');
    return;
  }

  setState(() {
    _isTranscribing = true;
    _isGeneratingSummary = true;
  });

  try {
    final result = await _aiService.transcribeAndSummarize(audioPath);
    if (result == null) {
      throw Exception('AI did not return a result');
    }
    if (mounted) {
      setState(() {
        _isTranscribing = false;
        _isGeneratingSummary = false;
        _transcription = result['transcription'];
        _summary = result['summary'];
        _suggestions = result['suggestions'];
      });
      final updatedEntry = JournalEntry(
        id: widget.entry.id,
        title: widget.entry.title,
        date: widget.entry.date,
        audioPath: widget.entry.audioPath,
        transcription: result['transcription'],
        summary: result['summary'],
        suggestions: result['suggestions'],
        duration: widget.entry.duration,
      );
  
      widget.onEntryUpdated?.call(updatedEntry);
      SnackBarUtils.showSuccess(context, 'Transcription and summary completed successfully');
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isTranscribing = false;
        _isGeneratingSummary = false;
      });
      SnackBarUtils.showError(context, 'Error: ${e.toString()}');
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Return true if auto-save has occurred to trigger parent reload
            debugPrint('🔙 EntryDetailsScreen: Manual back pressed, hasAutoSaved: $_hasAutoSaved');
            Navigator.of(context).pop(_hasAutoSaved);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Entry',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Entry'),
                  content: const Text('Are you sure you want to delete this entry? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  debugPrint('🗑️ EntryDetailsScreen: Starting deletion for entry ${widget.entry.id}');
                  await FirebaseService().deleteJournalEntry(widget.entry.id);
                  debugPrint('✅ EntryDetailsScreen: Entry deleted successfully from Firestore');
                  
                  // Refresh all screens after deletion
                  RefreshManager.refreshAfterDelete();
                  
                  if (mounted) {
                    debugPrint('🔙 EntryDetailsScreen: Popping with result=true after deletion');
                    Navigator.of(context).pop(true); // Optionally pass true to indicate deletion
                  } else {
                    debugPrint('⚠️ EntryDetailsScreen: Widget not mounted, cannot pop after deletion');
                  }
                } catch (e) {
                  debugPrint('❌ EntryDetailsScreen: Failed to delete entry: $e');
                  SnackBarUtils.showError(context, 'Failed to delete entry: $e');
                }
              }
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Entry header
                EntryHeader(
                  entry: _currentEntry,
                  onEntryUpdated: _onEntryUpdated,
                ),
                const SizedBox(height: 24),
                // Audio player section
                AudioControls(
                  isPlayerReady: _isPlayerReady,
                  isPlaying: _isPlaying,
                  duration: _duration,
                  position: _position,
                  fileSize: _fileSize,
                  onPlayPause: _playPause,
                  audioPlayer: _audioPlayer,
                ),
                const SizedBox(height: 24),
                // Transcription section
                TranscriptionSection(
                  transcription: _transcription,
                  isTranscribing: _isTranscribing,
                  onTranscribe: _transcribeAndSummarize,
                ),
                const SizedBox(height: 24),
                // Summary section
                SummarySection(
                  summary: _summary,
                  isGeneratingSummary: _isGeneratingSummary,
                  hasTranscription: _transcription != null && _transcription!.isNotEmpty,
                  onGenerateSummary: _transcribeAndSummarize,
                ),
                const SizedBox(height: 32),
                // Suggestions section
                SuggestionsSection(suggestions: _suggestions),
                const SizedBox(height: 32),
                // Notes section (modularized)
                NotesSection(
                  notesController: _notesController,
                  isSaving: _isSavingNotes,
                  hasUnsavedChanges: _hasUnsavedChanges,
                  onChanged: (value) {
                    setState(() {
                      _notes = value;
                    });
                    _scheduleAutoSave(); // Trigger auto-save
                  },
                  onSave: () async {
                    debugPrint('🔄 EntryDetailsScreen: Starting notes save for entry ${widget.entry.id}');
                    setState(() {
                      _isSavingNotes = true;
                    });
                    final updatedEntry = JournalEntry(
                      id: widget.entry.id,
                      title: widget.entry.title,
                      date: widget.entry.date,
                      audioPath: widget.entry.audioPath,
                      transcription: _transcription,
                      summary: _summary,
                      suggestions: _suggestions,
                      duration: widget.entry.duration,
                      notes: _notesController.text,
                      isFavorite: widget.entry.isFavorite, // Preserve favorite status
                    );
                    try {
                      debugPrint('💾 EntryDetailsScreen: Saving notes to Firestore...');
                      await FirebaseService().saveJournalEntry(updatedEntry);
                      debugPrint('✅ EntryDetailsScreen: Notes saved successfully to Firestore');
                      
                      widget.onEntryUpdated?.call(updatedEntry);
                      SnackBarUtils.showSuccess(context, 'Notes saved successfully');
                      // Don't pop - let user stay on screen with auto-save
                      debugPrint('✅ EntryDetailsScreen: Manual save completed, staying on screen');
                    } catch (e) {
                      debugPrint('❌ EntryDetailsScreen: Failed to save notes: $e');
                      SnackBarUtils.showError(context, 'Failed to save notes: $e');
                    } finally {
                      debugPrint('🏁 EntryDetailsScreen: Notes save operation completed');
                      setState(() {
                        _isSavingNotes = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  

  



}

