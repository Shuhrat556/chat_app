import 'package:chat_app/src/features/chat/data/models/chat_message_model.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:isar/isar.dart';

part 'chat_message_entity.g.dart';

@collection
class ChatMessageEntity {
  ChatMessageEntity({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String messageId;

  @Index(composite: [CompositeIndex('createdAt')])
  late String conversationId;

  late String senderId;
  late String receiverId;
  late String text;
  late DateTime createdAt;

  ChatMessageModel toModel() => ChatMessageModel(
        id: messageId,
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        createdAt: createdAt,
      );

  static ChatMessageEntity fromModel(ChatMessage message) => ChatMessageEntity(
        messageId: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        receiverId: message.receiverId,
        text: message.text,
        createdAt: message.createdAt,
      );
}
