import 'dart:async';

import 'package:chat_app/src/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:chat_app/src/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/src/features/chat/data/models/chat_message_model.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatLocalDataSource localDataSource,
    required ChatRemoteDataSource dataSource,
    required FirebaseAuth firebaseAuth,
  }) : _localDataSource = localDataSource,
       _dataSource = dataSource,
       _firebaseAuth = firebaseAuth;

  final ChatLocalDataSource _localDataSource;
  final ChatRemoteDataSource _dataSource;
  final FirebaseAuth _firebaseAuth;
  final _uuid = const Uuid();

  @override
  Stream<List<ChatMessage>> watchMessages({
    required String peerId,
    int limit = 40,
  }) {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }
    final conversationId = _conversationId(currentUser.uid, peerId);

    return Stream.multi((controller) {
      StreamSubscription<List<ChatMessage>>? localSub;
      StreamSubscription<List<ChatMessageModel>>? remoteSub;

      localSub = _localDataSource
          .watchRecentMessages(conversationId: conversationId, limit: limit)
          .listen(controller.add, onError: controller.addError);

      remoteSub = _dataSource
          .watchMessages(conversationId: conversationId, limit: limit)
          .listen(
            (messages) => unawaited(_localDataSource.cacheMessages(messages)),
            onError: (_, __) {
              // Keep local stream alive for offline usage.
            },
          );

      controller.onCancel = () async {
        await localSub?.cancel();
        await remoteSub?.cancel();
      };
    });
  }

  @override
  Future<List<ChatMessage>> loadOlderMessages({
    required String peerId,
    required DateTime beforeCreatedAt,
    required String beforeMessageId,
    int limit = 40,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Foydalanuvchi topilmadi',
      );
    }
    final conversationId = _conversationId(currentUser.uid, peerId);
    try {
      final remoteOlder = await _dataSource.loadOlderMessages(
        conversationId: conversationId,
        beforeCreatedAt: beforeCreatedAt,
        beforeMessageId: beforeMessageId,
        limit: limit,
      );
      if (remoteOlder.isNotEmpty) {
        await _localDataSource.cacheMessages(remoteOlder);
        return remoteOlder;
      }
    } catch (_) {
      // Fallback to local cache below.
    }

    return _localDataSource.loadOlderMessages(
      conversationId: conversationId,
      beforeCreatedAt: beforeCreatedAt,
      beforeMessageId: beforeMessageId,
      limit: limit,
    );
  }

  @override
  Future<void> sendMessage({
    required String peerId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Foydalanuvchi topilmadi',
      );
    }

    final conversationId = _conversationId(currentUser.uid, peerId);
    final message = ChatMessageModel(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: currentUser.uid,
      receiverId: peerId,
      text: trimmed,
      createdAt: DateTime.now(),
    );

    await _localDataSource.cacheMessage(message);
    await _dataSource.sendMessage(
      conversationId: conversationId,
      message: message,
    );
  }

  String _conversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted.first}_${sorted.last}';
  }
}
