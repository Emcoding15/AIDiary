import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'audio_processing_service.dart';

class AIService {
  final String _apiKey = ApiConfig.googleAiApiKey;
  final AudioProcessingService _audioProcessingService = AudioProcessingService();
  
  /// Transcribes audio from a file path
  Future<String?> transcribeAudio(String audioFilePath) async {
    try {
      // Check if the API key is set
      if (_apiKey == 'YOUR_GOOGLE_AI_API_KEY') {
        return 'Please set your Google AI API key in config/api_config.dart';
      }

      // Process and optimize the audio file for transcription
      print('Processing audio for transcription...');
      final processedAudioPath = await _audioProcessingService.prepareAudioForTranscription(audioFilePath);
      if (processedAudioPath == null) {
        return 'Failed to process audio file';
      }
      
      print('Using optimized audio file for transcription');
      
      // Get file info for context
      final File file = File(processedAudioPath);
      final fileSize = await file.length();
      final fileSizeKB = fileSize / 1024;
      print('Audio file size for transcription: ${fileSizeKB.toStringAsFixed(1)} KB');
      
      // For very short audio clips, try the direct API approach first
      try {
        print('Attempting direct API transcription...');
        final directResult = await _transcribeAudioDirectApi(processedAudioPath, isShortAudio: fileSizeKB < 500);
        if (directResult != null && directResult.isNotEmpty) {
          print('Direct API transcription successful');
          print('DIRECT API RESULT: "$directResult"');
          await _audioProcessingService.cleanupTempFiles();
          return directResult;
        }
        print('Direct API approach failed, falling back to base64 method');
      } catch (e) {
        print('Direct API error: $e - Falling back to base64 method');
      }
      
      // Convert to base64, limiting to 10MB if larger
      final int maxSizeBytes = 10 * 1024 * 1024; // 10MB limit
      final String audioBase64 = await _audioProcessingService.audioToBase64(
        processedAudioPath, 
        maxSizeBytes: fileSize > maxSizeBytes ? maxSizeBytes : null
      );
      
      // Create a model instance with Gemini 2.5 Pro
      final model = GenerativeModel(
        model: 'gemini-2.5-pro', // Using the latest model
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.0, // Zero temperature for most deterministic output
          topK: 1,
          topP: 1,
          maxOutputTokens: 8192, // Maximum allowed tokens for Gemini 2.5 Pro
        ),
      );
      
      // Create a specialized prompt based on audio length
      String promptText;
      if (fileSizeKB < 500) {
        // For very short audio clips (likely just a few words)
        promptText = "SYSTEM: You are an advanced speech recognition system with exceptional accuracy for short phrases.\n\n"
            "INSTRUCTIONS:\n"
            "- This is a VERY SHORT audio clip, likely containing only a few words or a short phrase\n"
            "- Transcribe EXACTLY what is spoken in the audio with perfect accuracy\n"
            "- DO NOT add any filler words or common phrases like 'the quick brown fox' if they are not present\n"
            "- DO NOT make assumptions about what might be said\n"
            "- If you can't make out the words clearly, respond with exactly what you hear, even if it's partial\n"
            "- DO NOT complete phrases or add words that aren't clearly audible\n"
            "- Include proper punctuation if appropriate\n"
            "- Respond ONLY with the exact words heard, nothing more\n\n"
            "AUDIO DATA:\n"
            "Format: WAV, Mono, 16kHz sample rate, optimized for speech recognition\n"
            "Size: ${fileSizeKB.toStringAsFixed(1)} KB (very short clip)\n"
            "Base64 encoded audio: $audioBase64\n\n"
            "RESPONSE FORMAT:\n"
            "Respond ONLY with the exact words heard. No explanations, no assumptions.";
      } else {
        // For longer recordings
        promptText = "SYSTEM: You are an advanced speech recognition system with exceptional accuracy. Your sole task is to transcribe the following audio perfectly.\n\n"
            "INSTRUCTIONS:\n"
            "- Transcribe EXACTLY what is spoken in the audio with perfect accuracy\n"
            "- Include proper punctuation, capitalization, and paragraphing\n"
            "- Maintain all spoken words exactly as heard, including filler words\n"
            "- Ignore all background noise\n"
            "- Do not add any commentary, descriptions, or explanations\n"
            "- Format naturally as a transcript\n"
            "- If multiple speakers are clearly distinct, label them as Speaker 1, Speaker 2, etc.\n"
            "- If speech is unclear, make your best guess rather than marking as [unclear]\n"
            "- CRITICAL: Return the COMPLETE transcript of the ENTIRE audio, regardless of length\n\n"
            "AUDIO DATA:\n"
            "Format: WAV, Mono, 16kHz sample rate, optimized for speech recognition\n"
            "Size: ${fileSizeKB.toStringAsFixed(1)} KB\n"
            "Base64 encoded audio: $audioBase64\n\n"
            "RESPONSE FORMAT:\n"
            "Respond ONLY with the transcript text. Do not include any explanations, comments, or descriptions about the audio or transcription process.";
      }
      
      final content = [Content.text(promptText)];
      
      // Generate content with enhanced retry logic
      print('Sending transcription request to Gemini API...');
      GenerateContentResponse? response;
      int retries = 0;
      const maxRetries = 3;
      
      while (retries <= maxRetries) {
        try {
          response = await model.generateContent(content);
          if (response.text != null && response.text!.isNotEmpty) {
            print('Transcription received successfully');
            break; // Successful, exit the loop
          }
          retries++;
          print('Empty response received, retrying (${retries}/${maxRetries})');
          await Future.delayed(Duration(seconds: 2 * retries)); // Exponential backoff
        } catch (e) {
          print('Transcription attempt $retries failed: $e');
          retries++;
          if (retries > maxRetries) {
            print('All retry attempts failed');
            rethrow;
          }
          await Future.delayed(Duration(seconds: 2 * retries)); // Exponential backoff
        }
      }
      
      // Clean up temporary files
      await _audioProcessingService.cleanupTempFiles();
      
      // If no transcription is detected
      if (response == null || response.text == null || response.text!.isEmpty) {
        return 'No speech detected in the audio file';
      }
      
      // Post-process the transcription for cleanliness
      String transcription = response.text!
          .replaceAll(RegExp(r'^\s*Transcript:\s*', caseSensitive: false), '') // Remove any "Transcript:" prefix
          .replaceAll(RegExp(r'^\s*Transcription:\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'\[background noise\]\s*'), '')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Normalize paragraph spacing
          .trim();
      
      print('Transcription completed and processed');
      print('TRANSCRIPTION RESULT: "$transcription"');
      return transcription;
    } catch (e) {
      // Clean up in case of error
      await _audioProcessingService.cleanupTempFiles();
      print('Error in transcription process: $e');
      return 'Error transcribing audio: $e';
    }
  }
  
  /// Attempts to transcribe audio using a more direct API approach
  /// This is more similar to how the Gemini app might handle audio transcription
  Future<String?> _transcribeAudioDirectApi(String audioFilePath, {bool isShortAudio = false}) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        return null;
      }
      
      // Create multipart request
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$_apiKey');
      
      // Read audio file as bytes
      final audioBytes = await file.readAsBytes();
      final fileSize = audioBytes.length / 1024; // Size in KB
      
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'inline_data': {
                  'mime_type': 'audio/wav',
                  'data': base64Encode(audioBytes)
                }
              },
              {
                'text': isShortAudio 
                    ? "This is a VERY SHORT audio clip. Transcribe EXACTLY what is spoken with perfect accuracy. DO NOT add any filler words or common phrases like 'the quick brown fox' if they are not present. DO NOT make assumptions about what might be said. Respond ONLY with the exact words heard, nothing more."
                    : "Please transcribe this audio with perfect accuracy. Include proper punctuation and formatting. Return the COMPLETE transcript of the ENTIRE audio, regardless of length."
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.0,
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': 8192 // Maximum allowed tokens for complete transcription
        }
      };
      
      // Convert request body to JSON
      final String jsonBody = jsonEncode(requestBody);
      
      // Set headers
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      // Send request
      print('Sending direct API request with JSON payload...');
      print('Audio file size: ${fileSize.toStringAsFixed(1)} KB');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonBody,
      );
      
      // Process response
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['candidates'] != null && 
            jsonResponse['candidates'].length > 0 && 
            jsonResponse['candidates'][0]['content'] != null &&
            jsonResponse['candidates'][0]['content']['parts'] != null &&
            jsonResponse['candidates'][0]['content']['parts'].length > 0) {
          
          final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          if (text != null && text.isNotEmpty) {
            return text.trim();
          }
        }
        
        // If we get here, the response format wasn't as expected
        print('Unexpected response format: ${response.body}');
      } else {
        print('Direct API request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      
      return null;
    } catch (e) {
      print('Error in direct API transcription: $e');
      return null;
    }
  }

  /// Generates a summary from a transcription
  Future<String?> generateSummary(String transcription) async {
    try {
      // Check if the API key is set
      if (_apiKey == 'YOUR_GOOGLE_AI_API_KEY') {
        return 'Please set your Google AI API key in config/api_config.dart';
      }

      print('Generating summary from transcription...');
      
      // Create a model instance with Gemini 2.5 Pro
      final model = GenerativeModel(
        model: 'gemini-2.5-pro', // Using the latest model
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2, // Low temperature for consistent summaries
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 4096, // Increased for longer summaries
        ),
      );
      
      // Generate a summary from the transcription with improved prompt
      final content = [
        Content.text(
          "SYSTEM: You are an expert summarization assistant that creates concise, accurate summaries while preserving key information.\n\n"
          "TASK: Create a clear, well-structured summary of the following transcription. Focus on the main points, key ideas, and important details.\n\n"
          "INSTRUCTIONS:\n"
          "- Identify and include all key points and important information\n"
          "- Maintain the original meaning and intent\n"
          "- Organize information logically with proper paragraphing\n"
          "- Use clear, concise language\n"
          "- Keep the summary comprehensive but brief\n\n"
          "TRANSCRIPTION TEXT:\n$transcription\n\n"
          "RESPONSE FORMAT:\n"
          "Provide only the summary without any introductory phrases like 'Here's a summary' or explanations of your process."
        ),
      ];
      
      final response = await model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        return 'Unable to generate summary';
      }
      
      // Clean up any potential prefixes
      String summary = response.text!
          .replaceAll(RegExp(r'^\s*Summary:\s*', caseSensitive: false), '')
          .trim();
      
      print('Summary generated successfully');
      return summary;
    } catch (e) {
      print('Error generating summary: $e');
      return 'Error generating summary: $e';
    }
  }
} 