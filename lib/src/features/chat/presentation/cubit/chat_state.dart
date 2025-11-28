part of 'chat_cubit.dart';

enum ChatStatus { initial, loading, loaded, error }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.peer,
    this.error,
    this.currentUserId,
  });

  final ChatStatus status;
  final List<ChatMessage> messages;
  final AppUser? peer;
  final String? error;
  final String? currentUserId;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    AppUser? peer,
    String? error,
    String? currentUserId,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      peer: peer ?? this.peer,
      error: error,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [status, messages, peer, error, currentUserId];
}
