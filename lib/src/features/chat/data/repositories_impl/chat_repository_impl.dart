import 'dart:async';

import 'package:chat_app/src/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:chat_app/src/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/src/features/chat/data/models/chat_message_model.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_conversation_preview.dart';
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
    final canonicalConversationId = _canonicalConversationId(
      currentUser.uid,
      peerId,
    );
    final conversationIds = _conversationIds(currentUser.uid, peerId);

    return Stream.multi((controller) {
      StreamSubscription<List<ChatMessage>>? localSub;
      final remoteSubs = <StreamSubscription<List<ChatMessageModel>>>[];
      List<ChatMessage> localMessages = const [];
      List<ChatMessage> remoteMessages = const [];
      final remoteByConversation = <String, List<ChatMessage>>{};

      void emitCombined() {
        controller.add(
          _mergeAndLimitMessages(
            localMessages: localMessages,
            remoteMessages: remoteMessages,
            limit: limit,
          ),
        );
      }

      localSub = _localDataSource
          .watchRecentMessages(
            conversationId: canonicalConversationId,
            limit: limit,
          )
          .listen((messages) {
            localMessages = messages;
            emitCombined();
          }, onError: controller.addError);

      for (final conversationId in conversationIds) {
        final sub = _dataSource
            .watchMessages(conversationId: conversationId, limit: limit)
            .listen(
              (messages) {
                remoteByConversation[conversationId] = messages;
                remoteMessages = _mergeAndLimitMessages(
                  localMessages: const [],
                  remoteMessages: remoteByConversation.values
                      .expand((it) => it)
                      .toList(growable: false),
                  limit: limit,
                );
                emitCombined();
                unawaited(_localDataSource.cacheMessages(messages));
              },
              onError: (_, __) {
                // Keep local stream alive for offline usage.
              },
            );
        remoteSubs.add(sub);
      }

      controller.onCancel = () async {
        await localSub?.cancel();
        for (final sub in remoteSubs) {
          await sub.cancel();
        }
      };
    });
  }

  @override
  Stream<Map<String, int>> watchUnreadCountsByPeer() {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return Stream.value(const <String, int>{});
    }
    return _dataSource.watchUnreadCountsByPeer(userId: currentUser.uid);
  }

  @override
  Stream<Map<String, ChatConversationPreview>>
  watchConversationPreviewsByPeer() {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return Stream.value(const <String, ChatConversationPreview>{});
    }
    return _dataSource.watchConversationPreviewsByPeer(userId: currentUser.uid);
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
    final conversationIds = _conversationIds(currentUser.uid, peerId);
    try {
      final remoteBatches = await Future.wait(
        conversationIds.map(
          (conversationId) => _dataSource.loadOlderMessages(
            conversationId: conversationId,
            beforeCreatedAt: beforeCreatedAt,
            beforeMessageId: beforeMessageId,
            limit: limit,
          ),
        ),
      );
      final remoteOlder = _mergeAndLimitMessages(
        localMessages: const [],
        remoteMessages: remoteBatches
            .expand((it) => it)
            .toList(growable: false),
        limit: limit,
      );
      if (remoteOlder.isNotEmpty) {
        await _localDataSource.cacheMessages(remoteOlder);
        return remoteOlder;
      }
    } catch (_) {
      // Fallback to local cache below.
    }

    final localBatches = await Future.wait(
      conversationIds.map(
        (conversationId) => _localDataSource.loadOlderMessages(
          conversationId: conversationId,
          beforeCreatedAt: beforeCreatedAt,
          beforeMessageId: beforeMessageId,
          limit: limit,
        ),
      ),
    );
    return _mergeAndLimitMessages(
      localMessages: localBatches.expand((it) => it).toList(growable: false),
      remoteMessages: const [],
      limit: limit,
    );
  }

  @override
  Future<void> sendMessage({
    required String peerId,
    required String text,
    String? imageUrl,
  }) async {
    final trimmed = text.trim();
    final cleanedImageUrl = imageUrl?.trim();
    final hasImage = cleanedImageUrl != null && cleanedImageUrl.isNotEmpty;
    if (trimmed.isEmpty && !hasImage) return;

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Foydalanuvchi topilmadi',
      );
    }

    final canonicalConversationId = _canonicalConversationId(
      currentUser.uid,
      peerId,
    );
    final conversationIds = _conversationIds(currentUser.uid, peerId);
    final messageId = _uuid.v4();
    final createdAt = DateTime.now();

    final canonicalMessage = ChatMessageModel(
      id: messageId,
      conversationId: canonicalConversationId,
      senderId: currentUser.uid,
      receiverId: peerId,
      text: trimmed,
      imageUrl: hasImage ? cleanedImageUrl : null,
      createdAt: createdAt,
    );

    await _localDataSource.cacheMessage(canonicalMessage);

    final sendTasks = conversationIds.map(
      (conversationId) => _dataSource.sendMessage(
        conversationId: conversationId,
        message: ChatMessageModel(
          id: messageId,
          conversationId: conversationId,
          senderId: currentUser.uid,
          receiverId: peerId,
          text: trimmed,
          imageUrl: hasImage ? cleanedImageUrl : null,
          createdAt: createdAt,
        ),
      ),
    );
    await Future.wait(sendTasks);
  }

  @override
  Future<void> markConversationRead({required String peerId}) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return;

    final conversationIds = _conversationIds(currentUser.uid, peerId);
    final tasks = conversationIds.map(
      (conversationId) => _dataSource.markConversationRead(
        conversationId: conversationId,
        userId: currentUser.uid,
      ),
    );
    await Future.wait(tasks);
  }

  String _canonicalConversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted.first}_${sorted.last}';
  }

  List<String> _conversationIds(String a, String b) {
    final ids = <String>{_canonicalConversationId(a, b), '${a}_$b', '${b}_$a'};
    return ids.toList(growable: false);
  }

  List<ChatMessage> _mergeAndLimitMessages({
    required List<ChatMessage> localMessages,
    required List<ChatMessage> remoteMessages,
    required int limit,
  }) {
    final byId = <String, ChatMessage>{};
    for (final message in localMessages) {
      byId[message.id] = message;
    }
    for (final message in remoteMessages) {
      byId[message.id] = message;
    }

    final merged = byId.values.toList(growable: false)
      ..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        if (byTime != 0) return byTime;
        return a.id.compareTo(b.id);
      });

    if (limit <= 0 || merged.length <= limit) {
      return merged;
    }
    return merged.sublist(merged.length - limit);
  }
}
