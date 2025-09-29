import '../services/settings_service.dart';

/// ApiConfig provides access to the Google AI API key, loaded from persistent settings.
class ApiConfig {
  /// Loads the Google AI API key from persistent storage.
  static Future<String?> getGoogleAiApiKey() async {
    final settings = await SettingsService.loadSettings();
    return settings['googleAiApiKey'] as String?;
  }
}
