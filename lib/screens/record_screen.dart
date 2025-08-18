import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/recording_service.dart';
import '../services/ai_service.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../services/firebase_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0;
  // Removed title controller (title is now AI-generated)
  final RecordingService _recordingService = RecordingService();
  final AIService _aiService = AIService();
  late Timer _timer;
  final Uuid _uuid = const Uuid();
  
  // File size tracking
  double _currentFileSize = 0.0;
  
  // Time limits
  static const int _warningTimeLimit = 480; // 8 minutes in seconds
  static const int _maxTimeLimit = 540; // 9 minutes in seconds
  bool _showWarning = false;
  
  // Animation controllers
  late AnimationController _micAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _waveformAnimationController;
  
  // Amplitude data for visualization
  final List<double> _amplitudeHistory = List.filled(30, 0.1);
  double _currentAmplitude = 0.1;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    
    // Initialize animation controllers
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _waveformAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _recordingService.checkPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission is required to record audio'),
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
  void dispose() {
  // _titleController removed
    if (_isRecording) {
      _stopTimer();
      _recordingService.cancelRecording();
    }
    _recordingService.dispose();
    _micAnimationController.dispose();
    _pulseAnimationController.dispose();
    _waveformAnimationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isRecording && !_isPaused) {
        setState(() {
          if (timer.tick % 10 == 0) {
            _recordingDuration++;
            
            // Check time limits
            if (_recordingDuration >= _maxTimeLimit) {
              // Auto-stop recording at max time limit
              _stopRecording();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Recording stopped: 9 minute maximum reached'),
                  backgroundColor: AppTheme.warningAmber,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
              );
            } else if (_recordingDuration >= _warningTimeLimit && !_showWarning) {
              // Show warning at warning time limit
              setState(() {
                _showWarning = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Recording approaching 9 minute limit. For best results, keep recordings under 8 minutes.'),
                  backgroundColor: AppTheme.warningAmber,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
              );
            }
          }
        });
        _updateAmplitude();
      }
    });
  }

  void _stopTimer() {
    _timer.cancel();
  }

  Future<void> _updateAmplitude() async {
    if (_isRecording && !_isPaused) {
      final amplitude = await _recordingService.getAmplitude() ?? 0.0;
      // Normalize amplitude to 0-1 range for visualization
      setState(() {
        // Shift amplitude history
        for (int i = 0; i < _amplitudeHistory.length - 1; i++) {
          _amplitudeHistory[i] = _amplitudeHistory[i + 1];
        }
        
        // Add new amplitude to history
        _currentAmplitude = (amplitude / 100).clamp(0.1, 1.0);
        _amplitudeHistory[_amplitudeHistory.length - 1] = _currentAmplitude;
      });
    }
  }
  
  Future<void> _updateFileSize() async {
    if (_recordingService.currentFilePath != null) {
      final fileSize = await _recordingService.getCurrentFileSize();
      if (fileSize != null && mounted) {
        setState(() {
          _currentFileSize = fileSize;
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      await _stopRecording();
    } else {
      // Start recording
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await _recordingService.startRecording();
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = 0;
        _currentAmplitude = 0.1;
        _currentFileSize = 0.0;
        _showWarning = false;
        _amplitudeHistory.fillRange(0, _amplitudeHistory.length, 0.1);
      });
      _startTimer();
      _micAnimationController.forward();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
      );
    }
  }

  Future<void> _stopRecording({bool showSnackBar = true}) async {
    final path = await _recordingService.stopRecording();
    _stopTimer();
    // Get final file size
    await _updateFileSize();
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
    _micAnimationController.reverse();
    if (showSnackBar && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recording saved successfully'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
      );
    }
  }

  Future<void> _pauseResumeRecording() async {
    if (_isPaused) {
      // Resume recording
      await _recordingService.resumeRecording();
      setState(() {
        _isPaused = false;
      });
    } else {
      // Pause recording
      await _recordingService.pauseRecording();
      setState(() {
        _isPaused = true;
      });
    }
  }

  Future<void> _saveRecording() async {
    try {
      if (_isRecording) {
        await _stopRecording();
      }

      // Get the file path of the recording
      final audioPath = _recordingService.currentFilePath;
      if (audioPath == null) {
        print('DEBUG: No recording found to save');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No recording found to save'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
          ),
        );
        return;
      }

      // Show loading dialog while processing
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Transcribe and summarize in a single request
      Map<String, dynamic>? result;
      try {
        result = await _aiService.transcribeAndSummarize(audioPath);
        print('DEBUG: Transcription result: $result');
        // Improved error handling: distinguish missing API key vs. Gemini/API error
        if (result == null) {
          Navigator.of(context).pop(); // Remove loading dialog
          final apiKey = await ApiConfig.getGoogleAiApiKey();
          final isApiKeyMissing = apiKey == null || apiKey.trim().isEmpty;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isApiKeyMissing
                  ? 'Please set your API key in Settings before transcribing.'
                  : 'Transcription failed due to a network or AI service error. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }
      } catch (e, stack) {
        print('DEBUG: Error during transcription: $e');
        print(stack);
        Navigator.of(context).pop(); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transcribe audio: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      if (result['transcription'] == null || (result['transcription']?.isEmpty ?? true)) {
        Navigator.of(context).pop(); // Remove loading dialog
        print('DEBUG: Transcription result is null or empty');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to transcribe audio.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      final transcription = result['transcription']!;
      final summary = result['summary']?.isNotEmpty == true ? result['summary'] : null;

      // Use the AI-generated title, fallback to 'Audio Entry' if empty
      String generatedTitle = result['title']?.isNotEmpty == true ? result['title']! : 'Audio Entry';

      // Create a new journal entry
      final journalEntry = JournalEntry(
        id: _uuid.v4(),
        title: generatedTitle,
        date: DateTime.now(),
        audioPath: audioPath,
        transcription: transcription,
        summary: summary,
        duration: _recordingDuration,
      );

      try {
        await FirebaseService().saveJournalEntry(journalEntry);
        print('DEBUG: Entry saved to Firestore!');
      } catch (e, stack) {
        print('DEBUG: Failed to save entry to Firestore: $e');
        print(stack);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry to Firestore: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }

      Navigator.of(context).pop(); // Remove loading dialog
      Navigator.pop(context, journalEntry);
    } catch (e, stack) {
      print('DEBUG: Unexpected error in _saveRecording: $e');
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
  Widget build(BuildContext context) {
    // Timer color based on recording duration
    Color timerColor = AppTheme.textPrimary;
    if (_isRecording) {
      if (_isPaused) {
        timerColor = AppTheme.warningAmber;
      } else if (_recordingDuration >= _warningTimeLimit) {
        timerColor = AppTheme.warningAmber;
      } else {
        timerColor = AppTheme.recordingRed;
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Journal Entry'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // Recording timer and file size
              Center(
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_recordingDuration),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRecording
                          ? (_isPaused ? 'Recording Paused' : 'Recording in Progress')
                          : 'Ready to Record',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _isRecording
                            ? (_isPaused ? AppTheme.warningAmber : AppTheme.recordingRed)
                            : AppTheme.textSecondary,
                      ),
                    ),
                    // Only show file size after recording is complete (not during recording)
                    if (!_isRecording && _currentFileSize > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatFileSize(_currentFileSize),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Show time warning when appropriate
                    if (_isRecording && _recordingDuration >= _warningTimeLimit) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Approaching ${_maxTimeLimit ~/ 60} minute limit',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.warningAmber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Audio visualization
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  boxShadow: AppTheme.lightShadow,
                ),
                child: _isRecording
                    ? _buildWaveformVisualizer()
                    : _buildMicrophoneAnimation(),
              ),
              
              const SizedBox(height: 40),
              
              // Record button
              AnimatedContainer(
                duration: AppTheme.shortAnimationDuration,
                height: 80,
                width: 80,
                child: ElevatedButton(
                  onPressed: _toggleRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? AppTheme.recordingRed : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    elevation: 4,
                  ),
                  child: AnimatedSwitcher(
                    duration: AppTheme.shortAnimationDuration,
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      key: ValueKey<bool>(_isRecording),
                      size: 36,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Additional controls
              if (_isRecording) ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    // Pause/Resume button
                    ElevatedButton.icon(
                      onPressed: _pauseResumeRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPaused
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.warningAmber,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                      label: Text(_isPaused ? 'Resume' : 'Pause'),
                    ),
                    // Save button
                    ElevatedButton.icon(
                      onPressed: _saveRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save'),
                    ),
                    // Discard button
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_isRecording) await _stopRecording(showSnackBar: false);
                        // Remove the current file if exists
                        if (_recordingService.currentFilePath != null) {
                          try {
                            final file = File(_recordingService.currentFilePath!);
                            if (await file.exists()) {
                              await file.delete();
                            }
                          } catch (_) {}
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(110, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Discard'),
                    ),
                  ],
                ),
              ] else ...[
                // Save/Discard buttons after recording
                if (_recordingService.currentFilePath != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saveRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save Entry'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Remove the current file if exists
                          if (_recordingService.currentFilePath != null) {
                            try {
                              final file = File(_recordingService.currentFilePath!);
                              if (await file.exists()) {
                                await file.delete();
                              }
                            } catch (_) {}
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('Discard'),
                      ),
                    ],
                  ),
                ],
              ],
              
              const SizedBox(height: 16),
              
              // Recording tips
              if (!_isRecording) ...[
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Recording Tips',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTipItem('Find a quiet place to record'),
                        _buildTipItem('Speak clearly and at a normal pace'),
                        _buildTipItem('Keep the phone about 6-12 inches from your mouth'),
                        _buildTipItem('Keep recordings under 8 minutes for best results'),
                        _buildTipItem('Recordings will automatically stop at 9 minutes'),
                        _buildTipItem('Titles and summaries are now generated automatically!'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMicrophoneAnimation() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimationController,
        builder: (context, child) {
          return Container(
            width: 80 + (20 * _pulseAnimationController.value),
            height: 80 + (20 * _pulseAnimationController.value),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1 * (1 - _pulseAnimationController.value)),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.mic_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildWaveformVisualizer() {
    return AnimatedBuilder(
      animation: _waveformAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: WaveformPainter(
            amplitudes: _amplitudeHistory,
            color: _isPaused ? AppTheme.warningAmber : AppTheme.recordingRed,
            animationValue: _waveformAnimationController.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final double animationValue;
  
  WaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    
    final path = Path();
    final barWidth = width / amplitudes.length;
    
    path.moveTo(0, centerY);
    
    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * barWidth;
      final normalizedAmplitude = amplitudes[i];
      
      // Add some randomness for a more natural look
      final randomFactor = sin((i * 0.4) + (animationValue * 2 * pi)) * 0.1;
      final adjustedAmplitude = normalizedAmplitude * (1 + randomFactor);
      
      final barHeight = adjustedAmplitude * (height * 0.4);
      
      // Draw top wave
      path.lineTo(x, centerY - barHeight);
      path.lineTo(x + barWidth * 0.5, centerY - (barHeight * 0.8));
      
      // Draw bottom wave (mirror of top)
      if (i == amplitudes.length - 1) {
        path.lineTo(width, centerY);
        path.lineTo(width, centerY);
        path.lineTo(x + barWidth * 0.5, centerY + (barHeight * 0.8));
      }
    }
    
    // Complete bottom wave
    for (int i = amplitudes.length - 1; i >= 0; i--) {
      final x = i * barWidth;
      final normalizedAmplitude = amplitudes[i];
      
      // Add some randomness for a more natural look
      final randomFactor = sin((i * 0.4) + (animationValue * 2 * pi)) * 0.1;
      final adjustedAmplitude = normalizedAmplitude * (1 + randomFactor);
      
      final barHeight = adjustedAmplitude * (height * 0.4);
      
      path.lineTo(x, centerY + barHeight);
      if (i > 0) {
        path.lineTo(x - barWidth * 0.5, centerY + (barHeight * 0.8));
      }
    }
    
    path.close();
    
    // Fill with gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.6),
          color.withOpacity(0.2),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}