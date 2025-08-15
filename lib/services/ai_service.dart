import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'audio_processing_service.dart';

class AIService {
  final AudioProcessingService _audioProcessingService = AudioProcessingService();

  Future<Map<String, String>?> transcribeAndSummarize(String audioFilePath) async {
  try {
    final apiKey = await ApiConfig.getGoogleAiApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return null;
    }
    final processedAudioPath = await _audioProcessingService.prepareAudioForTranscription(audioFilePath);
    if (processedAudioPath == null) {
      return null;
    }
    final File file = File(processedAudioPath);
    if (!await file.exists()) {
      return null;
    }
    final audioBytes = await file.readAsBytes();
  String promptText = 'You are an advanced speech recognition and summarization system. First, transcribe the following audio as accurately as possible. Then, provide a concise summary of the transcription. Then, generate a short, clear, and relevant title for the entry based on the main topic or summary. Respond ONLY in this JSON format: {"title": "...", "transcription": "...", "summary": "..."}. Do not include any other text or explanation.';
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey');
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
              'text': promptText
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.0,
        'topK': 1,
        'topP': 1,
        'maxOutputTokens': 8192
      }
    };
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    await _audioProcessingService.cleanupTempFiles();
    if (response.statusCode != 200) {
      print('Gemini API error: ${response.statusCode} ${response.body}');
      return null;
    }
    try {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['candidates'] != null &&
          jsonResponse['candidates'][0]['content'] != null &&
          jsonResponse['candidates'][0]['content']['parts'] != null &&
          jsonResponse['candidates'][0]['content']['parts'].length > 0) {
        final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        String cleaned = text.split('\n').where((line) => !line.trim().startsWith('```')).join('\n').trim();
  final Map<String, dynamic> result = jsonDecode(cleaned);
  final title = (result['title'] as String?)?.trim() ?? '';
  final transcription = (result['transcription'] as String?)?.trim() ?? '';
  final summary = (result['summary'] as String?)?.trim() ?? '';
  return {'title': title, 'transcription': transcription, 'summary': summary};
      } else {
        print('Unexpected Gemini response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Failed to parse JSON from Gemini response: $e');
      print('Gemini raw response: ${response.body}');
      return null;
    }
  } catch (e) {
    await _audioProcessingService.cleanupTempFiles();
    print('Error in transcribeAndSummarize: $e');
    return null;
  }
}
}


