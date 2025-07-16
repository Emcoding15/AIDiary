import 'dart:io';
import 'dart:convert';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class AudioProcessingService {
  /// Converts and optimizes audio for transcription
  /// 
  /// Takes an audio file path and returns the path to the processed file
  /// The processed file will be:
  /// - Converted to WAV format (optimal for speech recognition)
  /// - Mono channel (better for speech)
  /// - 16kHz sample rate (standard for speech recognition)
  /// - 16-bit depth (sufficient for speech)
  /// - Normalized audio levels
  /// - Enhanced speech clarity with noise reduction
  Future<String?> prepareAudioForTranscription(String audioFilePath) async {
    try {
      // Check if file exists
      final File originalFile = File(audioFilePath);
      if (!await originalFile.exists()) {
        throw Exception('Audio file not found');
      }

      // Get file size to determine processing approach
      final int fileSize = await originalFile.length();
      final double fileSizeKB = fileSize / 1024;
      print('Original audio file size: ${fileSizeKB.toStringAsFixed(1)} KB');

      // Get temp directory for output
      final Directory tempDir = await getTemporaryDirectory();
      final String outputFilePath = '${tempDir.path}/optimized_for_transcription.wav';
      
      String command;
      
      // Use different processing approaches based on file size
      if (fileSizeKB < 500) {
        // For very short audio clips (likely just a few words), use minimal processing
        // to avoid over-processing that might distort short speech samples
        print('Using minimal processing for short audio clip');
        command = '-y -i "$audioFilePath" -ac 1 -ar 16000 -c:a pcm_s16le "$outputFilePath"';
      } else {
        // For longer recordings, apply more extensive processing
        print('Using enhanced processing for longer audio recording');
        command = '-y -i "$audioFilePath" -ac 1 -ar 16000 -sample_fmt s16 ' +
                 '-af "highpass=f=100, lowpass=f=8000, ' +
                 'afftdn=nf=-25, ' +  // FFT-based denoiser
                 'equalizer=f=1000:width_type=o:width=1:g=2, ' + // Boost speech frequencies
                 'dynaudnorm=f=150:g=15:p=0.75, ' + // Dynamic audio normalization
                 'volume=1.5" ' + // Increase volume slightly
                 '-c:a pcm_s16le "$outputFilePath"';
      }
      
      print('Executing FFmpeg command: $command');
      
      // Execute FFmpeg command
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      // Check if conversion was successful
      if (ReturnCode.isSuccess(returnCode)) {
        // Verify the output file exists and has content
        final File outputFile = File(outputFilePath);
        if (await outputFile.exists() && await outputFile.length() > 0) {
          print('Audio processing successful: ${await outputFile.length()} bytes');
          return outputFilePath;
        } else {
          print('Output file is empty or does not exist');
          return audioFilePath;
        }
      } else {
        // Get error details if available
        final String? logs = await session.getLogsAsString();
        print('FFmpeg process failed with return code: ${returnCode?.getValue()}');
        print('FFmpeg logs: $logs');
        // Fall back to original file
        return audioFilePath;
      }
    } catch (e) {
      print('Error preparing audio: $e');
      // Return the original file path in case of error
      return audioFilePath;
    }
  }

  /// Converts audio file to base64 with optional chunking for large files
  Future<String> audioToBase64(String filePath, {int? maxSizeBytes}) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found');
      }

      final bytes = await file.readAsBytes();
      print('Converting audio to base64, file size: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
      
      // If maxSizeBytes is set and the file is larger, truncate it
      if (maxSizeBytes != null && bytes.length > maxSizeBytes) {
        print('File exceeds max size, truncating to ${(maxSizeBytes / 1024).toStringAsFixed(1)} KB');
        return base64Encode(bytes.sublist(0, maxSizeBytes));
      }
      
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting audio to base64: $e');
      throw e;
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File optimizedFile = File('${tempDir.path}/optimized_for_transcription.wav');
      
      if (await optimizedFile.exists()) {
        await optimizedFile.delete();
        print('Temporary audio file deleted');
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }
} 