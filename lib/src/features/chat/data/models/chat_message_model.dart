import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.receiverId,
    required super.text,
    super.imageUrl,
    required super.createdAt,
  });

  Map<String, dynamic> toMap({bool useServerTimestamp = false}) => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'imageUrl': imageUrl,
    'createdAt': useServerTimestamp
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt),
  };

  factory ChatMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Xabar hujjati bo\'sh: ${doc.id}');
    }

    final createdAtRaw = data['createdAt'] ?? data['timestamp'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }

    final inferredConversationId = doc.reference.parent.parent?.id ?? '';

    return ChatMessageModel(
      id: data['id'] as String? ?? doc.id,
      conversationId:
          data['conversationId'] as String? ?? inferredConversationId,
      senderId:
          data['senderId'] as String? ??
          data['fromUserId'] as String? ??
          data['fromId'] as String? ??
          '',
      receiverId:
          data['receiverId'] as String? ??
          data['toUserId'] as String? ??
          data['toId'] as String? ??
          '',
      text:
          data['text'] as String? ??
          data['body'] as String? ??
          data['message'] as String? ??
          '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: createdAt,
    );
  }
}
