import 'package:equatable/equatable.dart';

class ChatConversationPreview extends Equatable {
  const ChatConversationPreview({
    required this.peerId,
    required this.lastMessage,
    required this.unreadCount,
    this.lastMessageAt,
    this.lastMessageSenderId,
  });

  final String peerId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int unreadCount;

  @override
  List<Object?> get props => [
    peerId,
    lastMessage,
    lastMessageAt,
    lastMessageSenderId,
    unreadCount,
  ];
}
