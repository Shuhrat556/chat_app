import 'dart:async';

import 'package:chat_app/src/features/settings/data/settings_local_data_source.dart';
import 'package:chat_app/src/features/settings/data/settings_remote_data_source.dart';
import 'package:chat_app/src/features/settings/domain/settings_repository.dart';
import 'package:chat_app/src/features/settings/domain/user_settings.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required SettingsRemoteDataSource remoteDataSource,
    required SettingsLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final SettingsRemoteDataSource _remoteDataSource;
  final SettingsLocalDataSource _localDataSource;

  @override
  Future<UserSettings> getSettings({required String userId}) async {
    final local = await _localDataSource.fetchSettings(userId);
    try {
      final remote = await _remoteDataSource.fetchSettings(userId);
      final resolved = remote ?? local ?? const UserSettings();
      await _localDataSource.saveSettings(userId: userId, settings: resolved);
      if (remote == null) {
        await _remoteDataSource.saveSettings(
          userId: userId,
          settings: resolved,
        );
      }
      return resolved;
    } catch (_) {
      return local ?? const UserSettings();
    }
  }

  @override
  Stream<UserSettings> watchSettings({required String userId}) {
    return Stream.multi((controller) async {
      final local = await _localDataSource.fetchSettings(userId);
      controller.add(local ?? const UserSettings());

      final sub = _remoteDataSource
          .watchSettings(userId)
          .listen(
            (remote) async {
              final resolved = remote ?? local ?? const UserSettings();
              await _localDataSource.saveSettings(
                userId: userId,
                settings: resolved,
              );
              if (remote == null) {
                await _remoteDataSource.saveSettings(
                  userId: userId,
                  settings: resolved,
                );
              }
              controller.add(resolved);
            },
            onError: (_) {
              controller.add(local ?? const UserSettings());
            },
          );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<void> saveSettings({
    required String userId,
    required UserSettings settings,
  }) async {
    await _localDataSource.saveSettings(userId: userId, settings: settings);
    await _remoteDataSource.saveSettings(userId: userId, settings: settings);
  }

  @override
  Future<void> updateReadReceipts({
    required String userId,
    required bool enabled,
  }) async {
    final current = await getSettings(userId: userId);
    await saveSettings(
      userId: userId,
      settings: current.copyWith(readReceipts: enabled),
    );
  }

  @override
  Future<void> updateSecretChatDefaultOn({
    required String userId,
    required bool enabled,
  }) async {
    final current = await getSettings(userId: userId);
    await saveSettings(
      userId: userId,
      settings: current.copyWith(secretChatDefaultOn: enabled),
    );
  }

  @override
  Future<ThemeModePreference> loadThemePreference({String? userId}) async {
    if (userId == null) {
      return _localDataSource.fetchGlobalThemeMode();
    }
    final settings = await getSettings(userId: userId);
    return settings.themeMode;
  }

  @override
  Future<void> saveThemePreference({
    required ThemeModePreference mode,
    String? userId,
  }) async {
    if (userId == null) {
      await _localDataSource.saveGlobalThemeMode(mode);
      return;
    }
    final settings = await getSettings(userId: userId);
    await saveSettings(
      userId: userId,
      settings: settings.copyWith(themeMode: mode),
    );
  }
}
