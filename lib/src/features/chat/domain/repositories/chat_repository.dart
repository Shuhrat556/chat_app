import 'package:chat_app/src/features/chat/domain/entities/chat_conversation_preview.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchMessages({
    required String peerId,
    int limit = 40,
  });

  Stream<Map<String, int>> watchUnreadCountsByPeer();

  Stream<Map<String, ChatConversationPreview>>
  watchConversationPreviewsByPeer();

  Future<List<ChatMessage>> loadOlderMessages({
    required String peerId,
    required DateTime beforeCreatedAt,
    required String beforeMessageId,
    int limit = 40,
  });

  Future<void> sendMessage({
    required String peerId,
    required String text,
    String? imageUrl,
    int? ttlSeconds,
  });

  Future<void> markConversationRead({required String peerId});
}
