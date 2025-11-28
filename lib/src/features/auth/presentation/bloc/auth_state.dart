part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
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
    AppUser? user,
    String? message,
    String? verificationId,
    bool? otpSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message,
      verificationId: verificationId ?? this.verificationId,
      otpSent: otpSent ?? this.otpSent,
    );
  }

  @override
  List<Object?> get props => [status, user, message, verificationId, otpSent];
}
