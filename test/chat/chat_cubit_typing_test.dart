import 'dart:async';

import 'package:chat_app/src/features/auth/data/datasources/presence_remote_data_source.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/mark_conversation_read_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/watch_messages_usecase.dart';
import 'package:chat_app/src/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchMessagesUseCase extends Mock implements WatchMessagesUseCase {}

class _MockLoadOlderMessagesUseCase extends Mock
    implements LoadOlderMessagesUseCase {}

class _MockMarkConversationReadUseCase extends Mock
    implements MarkConversationReadUseCase {}

class _MockSendMessageUseCase extends Mock implements SendMessageUseCase {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockPresenceRemoteDataSource extends Mock
    implements PresenceRemoteDataSource {}

void main() {
  late _MockWatchMessagesUseCase watchMessagesUseCase;
  late _MockLoadOlderMessagesUseCase loadOlderMessagesUseCase;
  late _MockMarkConversationReadUseCase markConversationReadUseCase;
  late _MockSendMessageUseCase sendMessageUseCase;
  late _MockFirebaseAuth firebaseAuth;
  late _MockUser user;
  late _MockPresenceRemoteDataSource presenceRemoteDataSource;
  late StreamController<Set<String>> typingController;

  setUp(() {
    watchMessagesUseCase = _MockWatchMessagesUseCase();
    loadOlderMessagesUseCase = _MockLoadOlderMessagesUseCase();
    markConversationReadUseCase = _MockMarkConversationReadUseCase();
    sendMessageUseCase = _MockSendMessageUseCase();
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    presenceRemoteDataSource = _MockPresenceRemoteDataSource();
    typingController = StreamController<Set<String>>.broadcast();

    when(() => user.uid).thenReturn('me');
    when(() => firebaseAuth.currentUser).thenReturn(user);

    when(
      () => watchMessagesUseCase(
        peerId: any(named: 'peerId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) => Stream<List<ChatMessage>>.value(const []));
    when(
      () => loadOlderMessagesUseCase(
        peerId: any(named: 'peerId'),
        beforeCreatedAt: any(named: 'beforeCreatedAt'),
        beforeMessageId: any(named: 'beforeMessageId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => markConversationReadUseCase(peerId: any(named: 'peerId')),
    ).thenAnswer((_) async {});
    when(
      () => sendMessageUseCase(
        peerId: any(named: 'peerId'),
        text: any(named: 'text'),
        imageUrl: any(named: 'imageUrl'),
        ttlSeconds: any(named: 'ttlSeconds'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => presenceRemoteDataSource.watchTypingUsers(any()),
    ).thenAnswer((_) => typingController.stream);
    when(
      () => presenceRemoteDataSource.setTyping(any(), any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await typingController.close();
  });

  test('updates state when peer typing status changes', () async {
    final cubit = ChatCubit(
      watchMessagesUseCase: watchMessagesUseCase,
      loadOlderMessagesUseCase: loadOlderMessagesUseCase,
      markConversationReadUseCase: markConversationReadUseCase,
      sendMessageUseCase: sendMessageUseCase,
      firebaseAuth: firebaseAuth,
      presenceRemoteDataSource: presenceRemoteDataSource,
    );

    const peer = AppUser(
      id: 'peer1',
      email: 'peer@test.com',
      username: 'peerx',
    );
    cubit.start(peer);

    typingController.add({'peer1'});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cubit.state.isTyping, true);

    typingController.add(const <String>{});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cubit.state.isTyping, false);

    await cubit.close();
  });

  test('writes typing flag to realtime db on start and stop', () async {
    final cubit = ChatCubit(
      watchMessagesUseCase: watchMessagesUseCase,
      loadOlderMessagesUseCase: loadOlderMessagesUseCase,
      markConversationReadUseCase: markConversationReadUseCase,
      sendMessageUseCase: sendMessageUseCase,
      firebaseAuth: firebaseAuth,
      presenceRemoteDataSource: presenceRemoteDataSource,
    );

    const peer = AppUser(
      id: 'peer1',
      email: 'peer@test.com',
      username: 'peerx',
    );
    cubit.start(peer);

    cubit.onTypingStarted();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    cubit.onTypingStopped();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(
      () => presenceRemoteDataSource.setTyping('me_peer1', true),
    ).called(1);
    verify(
      () => presenceRemoteDataSource.setTyping('me_peer1', false),
    ).called(greaterThanOrEqualTo(1));

    await cubit.close();
  });
}
