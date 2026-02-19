import 'dart:async';

import 'package:chat_app/src/core/theme/theme_cubit.dart';
import 'package:chat_app/src/features/settings/domain/settings_repository.dart';
import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _FakeSettingsRepository implements SettingsRepository {
  ThemeModePreference global = ThemeModePreference.system;
  final Map<String, UserSettings> byUser = {};

  @override
  Future<UserSettings> getSettings({required String userId}) async {
    return byUser[userId] ?? const UserSettings();
  }

  @override
  Stream<UserSettings> watchSettings({required String userId}) async* {
    yield byUser[userId] ?? const UserSettings();
  }

  @override
  Future<void> saveSettings({
    required String userId,
    required UserSettings settings,
  }) async {
    byUser[userId] = settings;
    global = settings.themeMode;
  }

  @override
  Future<void> updateReadReceipts({
    required String userId,
    required bool enabled,
  }) async {
    final current = byUser[userId] ?? const UserSettings();
    byUser[userId] = current.copyWith(readReceipts: enabled);
  }

  @override
  Future<void> updateSecretChatDefaultOn({
    required String userId,
    required bool enabled,
  }) async {
    final current = byUser[userId] ?? const UserSettings();
    byUser[userId] = current.copyWith(secretChatDefaultOn: enabled);
  }

  @override
  Future<ThemeModePreference> loadThemePreference({String? userId}) async {
    if (userId == null) return global;
    return (byUser[userId] ?? const UserSettings()).themeMode;
  }

  @override
  Future<void> saveThemePreference({
    required ThemeModePreference mode,
    String? userId,
  }) async {
    global = mode;
    if (userId != null) {
      final current = byUser[userId] ?? const UserSettings();
      byUser[userId] = current.copyWith(themeMode: mode);
    }
  }
}

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late _FakeSettingsRepository settingsRepository;
  late StreamController<User?> authController;

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    settingsRepository = _FakeSettingsRepository();
    authController = StreamController<User?>.broadcast();

    when(
      () => firebaseAuth.authStateChanges(),
    ).thenAnswer((_) => authController.stream);
  });

  tearDown(() async {
    await authController.close();
  });

  test('loads system mode by default and persists updates', () async {
    when(() => firebaseAuth.currentUser).thenReturn(null);
    final cubit = ThemeCubit(
      settingsRepository: settingsRepository,
      firebaseAuth: firebaseAuth,
    );

    await cubit.start();
    expect(cubit.state.preference, ThemeModePreference.system);

    await cubit.setThemeMode(ThemeModePreference.dark);
    expect(cubit.state.preference, ThemeModePreference.dark);
    expect(settingsRepository.global, ThemeModePreference.dark);
    await cubit.close();
  });

  test('loads user-specific theme after auth change', () async {
    final user = _MockUser();
    when(() => user.uid).thenReturn('u-1');
    when(() => firebaseAuth.currentUser).thenReturn(null);
    settingsRepository.byUser['u-1'] = const UserSettings(
      themeMode: ThemeModePreference.light,
    );

    final cubit = ThemeCubit(
      settingsRepository: settingsRepository,
      firebaseAuth: firebaseAuth,
    );
    await cubit.start();

    when(() => firebaseAuth.currentUser).thenReturn(user);
    authController.add(user);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cubit.state.preference, ThemeModePreference.light);
    await cubit.close();
  });
}
