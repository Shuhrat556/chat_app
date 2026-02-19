import 'dart:convert';

import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalDataSource {
  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static const _themeGlobalKey = 'theme_mode_global';
  static const _settingsPrefix = 'user_settings_';

  Future<UserSettings?> fetchSettings(String userId) async {
    final prefs = await _prefs();
    final raw = prefs.getString('$_settingsPrefix$userId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return UserSettings.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSettings({
    required String userId,
    required UserSettings settings,
  }) async {
    final prefs = await _prefs();
    await prefs.setString(
      '$_settingsPrefix$userId',
      jsonEncode(settings.toMap()),
    );
    await prefs.setString(
      _themeGlobalKey,
      themeModePreferenceToString(settings.themeMode),
    );
  }

  Future<ThemeModePreference> fetchGlobalThemeMode() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_themeGlobalKey);
    return themeModePreferenceFromString(raw);
  }

  Future<void> saveGlobalThemeMode(ThemeModePreference mode) async {
    final prefs = await _prefs();
    await prefs.setString(_themeGlobalKey, themeModePreferenceToString(mode));
  }
}
