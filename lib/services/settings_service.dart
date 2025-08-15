import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service to handle persistent settings storage (e.g., API key)
class SettingsService {
  static const String _settingsFileName = 'settings.json';

  /// Loads the settings from the persistent file
  static Future<Map<String, dynamic>> loadSettings() async {
    final file = await _getSettingsFile();
    if (await file.exists()) {
      final contents = await file.readAsString();
      return jsonDecode(contents);
    }
    return {};
  }

  /// Saves the settings to the persistent file
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final file = await _getSettingsFile();
    await file.writeAsString(jsonEncode(settings));
  }

  /// Gets the settings file in the app's documents directory
  static Future<File> _getSettingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_settingsFileName');
  }
}
