import '../widgets/transcription_section.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/journal_entry.dart';
import '../services/ai_service.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/audio_controls.dart';
import '../config/theme.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../widgets/entry_header.dart';

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
  
  // Animation controller for content transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _loadFileSize();
    _transcription = widget.entry.transcription;
    _summary = widget.entry.summary;
    _suggestions = widget.entry.suggestions;
    
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
        _audioPlayer.playerStateStream.listen((state) {
          if (!mounted) return;
          if (state.playing != _isPlaying) {
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }



  Future<void> _transcribeAndSummarize() async {
  final audioPath = widget.entry.audioPath;
  if (audioPath == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No audio file available to transcribe and summarize'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transcription and summary completed successfully'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isTranscribing = false;
        _isGeneratingSummary = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title),
        elevation: 0,
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
                  await FirebaseService().deleteJournalEntry(widget.entry.id);
                  if (mounted) {
                    Navigator.of(context).pop(true); // Optionally pass true to indicate deletion
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete entry: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
                EntryHeader(entry: widget.entry),
                
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
                _buildSummarySection(),
                
                const SizedBox(height: 32),
                
                // Suggestions section
                _buildSuggestionsSection(),
                // Bottom padding
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  

  
  Widget _buildSummarySection() {
    final hasTranscription = _transcription != null && _transcription!.isNotEmpty;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize_rounded,
                  color: Color(0xFF4EE0BD),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (hasTranscription && (_summary == null || _summary!.isEmpty))
                  ElevatedButton.icon(
                    onPressed: _isGeneratingSummary ? null : _transcribeAndSummarize,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    icon: _isGeneratingSummary
                        ? Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(right: 8),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(_isGeneratingSummary ? 'Processing...' : 'Generate'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 2, color: Color(0xFF232B3A)),
            const SizedBox(height: 16),
            if (_summary != null && _summary!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(
                  _summary!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
              )
            else if (_isGeneratingSummary)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generating summary...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a minute',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Center(
                  child: Text(
                    hasTranscription
                        ? 'Generate a summary from the transcription'
                        : 'Transcription required for summary generation',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    // Remove debug print for production
    if (_suggestions == null || _suggestions!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    // Split suggestions into lines
    List<String> lines = _suggestions!.split('\n').where((l) => l.trim().isNotEmpty).toList();
    // If only one line, try splitting by ' - '
    if (lines.length <= 1 && _suggestions!.contains(' - ')) {
      lines = _suggestions!
          .split(' - ')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    }
    // Clean up each line: remove leading dashes or bullets
    lines = lines.map((l) {
      String cleaned = l.trim();
      if (cleaned.startsWith('-')) cleaned = cleaned.substring(1).trim();
      if (cleaned.startsWith('•')) cleaned = cleaned.substring(1).trim();
      return cleaned;
    }).toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Color(0xFF4EE0BD), size: 22),
                const SizedBox(width: 8),
                Text('Suggestions', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                )),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 2, color: Color(0xFF232B3A)),
            const SizedBox(height: 16),
            ...lines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•', style: TextStyle(fontSize: 28, height: 1.1, color: Color(0xFF4EE0BD))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Color color;
  
  WaveformPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    
    final path = Path();
    
    // Create a simple static waveform pattern
    final segmentWidth = width / 40;
    path.moveTo(0, centerY);
    
    for (int i = 0; i < 40; i++) {
      final x = i * segmentWidth;
      final amplitude = (i % 3 == 0) ? 0.7 : (i % 2 == 0 ? 0.4 : 0.2);
      final y = centerY - (height * 0.3 * amplitude);
      
      path.lineTo(x, y);
      path.lineTo(x + segmentWidth * 0.5, centerY);
      path.lineTo(x + segmentWidth, centerY + (height * 0.3 * amplitude * 0.7));
      path.lineTo(x + segmentWidth * 1.5, centerY);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}