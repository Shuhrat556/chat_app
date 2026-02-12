import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchMessages({
    required String peerId,
    int limit = 40,
  });

  Future<List<ChatMessage>> loadOlderMessages({
    required String peerId,
    required DateTime beforeCreatedAt,
    required String beforeMessageId,
    int limit = 40,
  });

  Future<void> sendMessage({required String peerId, required String text});
}
