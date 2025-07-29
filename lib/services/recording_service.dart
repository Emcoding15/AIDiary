import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentFilePath;
  final Uuid _uuid = const Uuid();

  bool get isRecording => _isRecording;
  String? get currentFilePath => _currentFilePath;

  // Check and request microphone permissions
  Future<bool> checkPermission() async {
    return await _audioRecorder.hasPermission();
  }

  // Start recording
  Future<void> startRecording() async {
    if (await checkPermission()) {
      // Generate a file path
      final String filePath = await _generateFilePath();
      _currentFilePath = filePath;

      // Configure recording options
      final RecordConfig config = RecordConfig(
        encoder: AudioEncoder.aacLc, // AAC-LC format
        bitRate: 128000, // 128 kbps
        sampleRate: 44100, // 44.1 kHz
        numChannels: 2, // Stereo
      );

      // Start recording
      await _audioRecorder.start(config, path: filePath);
      _isRecording = true;
    } else {
      throw Exception('Microphone permission not granted');
    }
  }

  // Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path;
    }
    return null;
  }

  // Pause recording
  Future<void> pauseRecording() async {
    if (_isRecording) {
      await _audioRecorder.pause();
    }
  }

  // Resume recording
  Future<void> resumeRecording() async {
    if (_isRecording) {
      await _audioRecorder.resume();
    }
  }

  // Cancel recording and delete the file
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _audioRecorder.cancel();
      _isRecording = false;
      
      // Delete the file if it exists
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentFilePath = null;
      }
    }
  }

  // Get the current amplitude (for visualizing audio levels)
  Future<double?> getAmplitude() async {
    if (_isRecording) {
      final amplitude = await _audioRecorder.getAmplitude();
      return amplitude.current;
    }
    return null;
  }

  // Get the current file size in KB
  Future<double?> getCurrentFileSize() async {
    if (_currentFilePath != null) {
      final File file = File(_currentFilePath!);
      if (await file.exists()) {
        final int fileSize = await file.length();
        return fileSize / 1024; // Convert to KB
      }
    }
    return null;
  }

  // Generate a unique file path for the recording
  Future<String> _generateFilePath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    final String fileName = 'audio_journal_${_uuid.v4()}.m4a';
    return '$appDocPath/$fileName';
  }

  // Dispose resources
  void dispose() {
    _audioRecorder.dispose();
  }
} 