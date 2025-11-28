part of 'users_cubit.dart';

enum UsersStatus { initial, loading, loaded, error }

class UsersState extends Equatable {
  const UsersState({
    this.status = UsersStatus.initial,
    this.users = const [],
    this.error,
  });

  final UsersStatus status;
  final List<AppUser> users;
  final String? error;

  UsersState copyWith({
    UsersStatus? status,
    List<AppUser>? users,
    String? error,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, users, error];
}
