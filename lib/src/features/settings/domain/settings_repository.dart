import 'package:chat_app/src/features/settings/domain/user_settings.dart';

abstract class SettingsRepository {
  Future<UserSettings> getSettings({required String userId});

  Stream<UserSettings> watchSettings({required String userId});

  Future<void> saveSettings({
    required String userId,
    required UserSettings settings,
  });

  Future<void> updateReadReceipts({
    required String userId,
    required bool enabled,
  });

  Future<void> updateSecretChatDefaultOn({
    required String userId,
    required bool enabled,
  });

  Future<ThemeModePreference> loadThemePreference({String? userId});

  Future<void> saveThemePreference({
    required ThemeModePreference mode,
    String? userId,
  });
}
