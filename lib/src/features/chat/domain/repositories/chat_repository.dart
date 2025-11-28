import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchMessages({
    required String peerId,
  });

  Future<void> sendMessage({
    required String peerId,
    required String text,
  });
}
