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
    super.status = MessageStatus.sent,
    super.deliveredAt,
    super.readAt,
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
    'status': status.name,
    'deliveredAt': deliveredAt != null
        ? Timestamp.fromDate(deliveredAt!)
        : null,
    'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
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

    // Parse message status
    MessageStatus status = MessageStatus.sent;
    final statusRaw = data['status'] as String?;
    if (statusRaw != null) {
      try {
        status = MessageStatus.values.firstWhere(
          (e) => e.name == statusRaw,
          orElse: () => MessageStatus.sent,
        );
      } catch (_) {
        status = MessageStatus.sent;
      }
    }

    // Parse timestamps
    DateTime? deliveredAt;
    final deliveredRaw = data['deliveredAt'];
    if (deliveredRaw is Timestamp) {
      deliveredAt = deliveredRaw.toDate();
    } else if (deliveredRaw is int) {
      deliveredAt = DateTime.fromMillisecondsSinceEpoch(deliveredRaw);
    }

    DateTime? readAt;
    final readRaw = data['readAt'];
    if (readRaw is Timestamp) {
      readAt = readRaw.toDate();
    } else if (readRaw is int) {
      readAt = DateTime.fromMillisecondsSinceEpoch(readRaw);
    }

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
      status: status,
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }

  ChatMessageModel copyWithStatus({
    MessageStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return ChatMessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      imageUrl: imageUrl,
      createdAt: createdAt,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
