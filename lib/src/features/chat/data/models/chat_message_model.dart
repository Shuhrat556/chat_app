import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel extends ChatMessage {
  ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.receiverId,
    required super.text,
    required super.createdAt,
  });

  Map<String, dynamic> toMap({bool useServerTimestamp = false}) => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'createdAt':
            useServerTimestamp ? FieldValue.serverTimestamp() : createdAt.millisecondsSinceEpoch,
      };

  factory ChatMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Xabar hujjati bo\'sh: ${doc.id}');
    }

    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }

    return ChatMessageModel(
      id: data['id'] as String? ?? doc.id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}
