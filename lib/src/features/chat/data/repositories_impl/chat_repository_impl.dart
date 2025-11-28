import 'package:chat_app/src/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:chat_app/src/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/src/features/chat/data/models/chat_message_model.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatRemoteDataSource dataSource,
    required FirebaseAuth firebaseAuth,
    required ChatLocalDataSource localDataSource,
  })  : _dataSource = dataSource,
        _firebaseAuth = firebaseAuth,
        _localDataSource = localDataSource;

  final ChatRemoteDataSource _dataSource;
  final ChatLocalDataSource _localDataSource;
  final FirebaseAuth _firebaseAuth;
  final _uuid = const Uuid();

  @override
  Stream<List<ChatMessage>> watchMessages({required String peerId}) {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }
    final conversationId = _conversationId(currentUser.uid, peerId);

    // Watch remote and persist locally; surface local stream for offline/cache.
    _dataSource.watchMessages(conversationId: conversationId).listen(
      (remoteMessages) => _localDataSource.saveMessages(remoteMessages),
    );

    return _localDataSource.watchMessages(conversationId: conversationId);
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

    await _dataSource.sendMessage(
      conversationId: conversationId,
      message: message,
    );
    await _localDataSource.saveMessages([message]);
  }

  String _conversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted.first}_${sorted.last}';
  }
}
