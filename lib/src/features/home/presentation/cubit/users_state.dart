part of 'users_cubit.dart';

enum UsersStatus { initial, loading, loaded, error }

class UsersState extends Equatable {
  const UsersState({
    this.status = UsersStatus.initial,
    this.users = const [],
    this.unreadByUserId = const {},
    this.conversationsByUserId = const {},
    this.error,
  });

  final UsersStatus status;
  final List<AppUser> users;
  final Map<String, int> unreadByUserId;
  final Map<String, ChatConversationPreview> conversationsByUserId;
  final String? error;

  UsersState copyWith({
    UsersStatus? status,
    List<AppUser>? users,
    Map<String, int>? unreadByUserId,
    Map<String, ChatConversationPreview>? conversationsByUserId,
    String? error,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      unreadByUserId: unreadByUserId ?? this.unreadByUserId,
      conversationsByUserId:
          conversationsByUserId ?? this.conversationsByUserId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    users,
    unreadByUserId,
    conversationsByUserId,
    error,
  ];
}
