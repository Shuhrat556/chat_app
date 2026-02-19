import 'package:chat_app/src/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:chat_app/src/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/src/features/chat/data/repositories_impl/chat_repository_impl.dart';
import 'package:chat_app/src/features/settings/domain/settings_repository.dart';
import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _RecordingChatRemoteDataSource extends ChatRemoteDataSource {
  _RecordingChatRemoteDataSource() : super(FakeFirebaseFirestore());

  int markReadCalls = 0;
  int markConversationReadCalls = 0;

  @override
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String receiverId,
  }) async {
    markReadCalls++;
  }

  @override
  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
  }) async {
    markConversationReadCalls++;
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.readReceipts);

  final bool readReceipts;

  @override
  Future<UserSettings> getSettings({required String userId}) async {
    return UserSettings(readReceipts: readReceipts);
  }

  @override
  Stream<UserSettings> watchSettings({required String userId}) async* {
    yield UserSettings(readReceipts: readReceipts);
  }

  @override
  Future<void> saveSettings({
    required String userId,
    required UserSettings settings,
  }) async {}

  @override
  Future<void> updateReadReceipts({
    required String userId,
    required bool enabled,
  }) async {}

  @override
  Future<void> updateSecretChatDefaultOn({
    required String userId,
    required bool enabled,
  }) async {}

  @override
  Future<ThemeModePreference> loadThemePreference({String? userId}) async {
    return ThemeModePreference.system;
  }

  @override
  Future<void> saveThemePreference({
    required ThemeModePreference mode,
    String? userId,
  }) async {}
}

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late _MockUser user;
  late _RecordingChatRemoteDataSource remoteDataSource;
  late ChatLocalDataSource localDataSource;

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    remoteDataSource = _RecordingChatRemoteDataSource();
    localDataSource = ChatLocalDataSource();
    when(() => user.uid).thenReturn('u1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
  });

  test(
    'skips message read status updates when read receipts are disabled',
    () async {
      final repository = ChatRepositoryImpl(
        localDataSource: localDataSource,
        dataSource: remoteDataSource,
        firebaseAuth: firebaseAuth,
        settingsRepository: _FakeSettingsRepository(false),
      );

      await repository.markConversationRead(peerId: 'u2');

      expect(remoteDataSource.markConversationReadCalls, greaterThan(0));
      expect(remoteDataSource.markReadCalls, 0);
    },
  );

  test('updates read statuses when read receipts are enabled', () async {
    final repository = ChatRepositoryImpl(
      localDataSource: localDataSource,
      dataSource: remoteDataSource,
      firebaseAuth: firebaseAuth,
      settingsRepository: _FakeSettingsRepository(true),
    );

    await repository.markConversationRead(peerId: 'u2');

    expect(remoteDataSource.markConversationReadCalls, greaterThan(0));
    expect(remoteDataSource.markReadCalls, greaterThan(0));
  });
}
