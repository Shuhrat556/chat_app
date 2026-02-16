import 'package:equatable/equatable.dart';

enum MessageStatus { sending, sent, delivered, read }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.deliveredAt,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final MessageStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? text,
    String? imageUrl,
    DateTime? createdAt,
    MessageStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    receiverId,
    text,
    imageUrl,
    createdAt,
    status,
    deliveredAt,
    readAt,
  ];
}
