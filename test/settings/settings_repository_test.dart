import 'package:chat_app/src/features/settings/data/settings_local_data_source.dart';
import 'package:chat_app/src/features/settings/data/settings_remote_data_source.dart';
import 'package:chat_app/src/features/settings/data/settings_repository_impl.dart';
import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SettingsRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    firestore = FakeFirebaseFirestore();
    repository = SettingsRepositoryImpl(
      remoteDataSource: SettingsRemoteDataSource(firestore),
      localDataSource: SettingsLocalDataSource(),
    );
  });

  test('save and get settings roundtrip', () async {
    const userId = 'user-1';
    const expected = UserSettings(
      readReceipts: false,
      secretChatDefaultOn: true,
      themeMode: ThemeModePreference.dark,
    );

    await repository.saveSettings(userId: userId, settings: expected);
    final loaded = await repository.getSettings(userId: userId);

    expect(loaded, expected);
  });

  test('update readReceipts and secret default flags', () async {
    const userId = 'user-2';

    await repository.saveSettings(
      userId: userId,
      settings: const UserSettings(),
    );
    await repository.updateReadReceipts(userId: userId, enabled: false);
    await repository.updateSecretChatDefaultOn(userId: userId, enabled: false);

    final loaded = await repository.getSettings(userId: userId);
    expect(loaded.readReceipts, false);
    expect(loaded.secretChatDefaultOn, false);
  });
}
