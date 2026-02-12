part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  static const _sentinel = Object();

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.message,
    this.verificationId,
    this.otpSent = false,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? message;
  final String? verificationId;
  final bool otpSent;

  AuthState copyWith({
    AuthStatus? status,
    Object? user = _sentinel,
    String? message,
    Object? verificationId = _sentinel,
    bool? otpSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _sentinel) ? this.user : user as AppUser?,
      message: message,
      verificationId: identical(verificationId, _sentinel)
          ? this.verificationId
          : verificationId as String?,
      otpSent: otpSent ?? this.otpSent,
    );
  }

  @override
  List<Object?> get props => [status, user, message, verificationId, otpSent];
}
