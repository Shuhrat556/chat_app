part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthStatusChanged extends AuthEvent {
  const AuthStatusChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}

class SignInRequested extends AuthEvent {
  const SignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  const SignUpRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    this.photoUrl,
    this.bio,
  });

  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String? photoUrl;
  final String? bio;

  @override
  List<Object?> get props =>
      [username, email, password, firstName, lastName, birthDate, photoUrl, bio];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class PhoneOtpRequested extends AuthEvent {
  const PhoneOtpRequested({required this.phoneNumber});

  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class PhoneOtpSubmitted extends AuthEvent {
  const PhoneOtpSubmitted({
    required this.verificationId,
    required this.smsCode,
    this.username,
  });

  final String verificationId;
  final String smsCode;
  final String? username;

  @override
  List<Object?> get props => [verificationId, smsCode, username];
}
