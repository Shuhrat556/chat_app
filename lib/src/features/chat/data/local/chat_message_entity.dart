import 'package:isar/isar.dart';

part 'chat_message_entity.g.dart';

@collection
class ChatMessageEntity {
  ChatMessageEntity();

  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String messageId;

  @Index()
  late String conversationId;

  @Index()
  late DateTime createdAt;

  late String senderId;
  late String receiverId;
  late String text;
}
