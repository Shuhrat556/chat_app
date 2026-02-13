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
    required this.confirmPassword,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.photoUrl,
    this.bio,
  });

  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? photoUrl;
  final String? bio;

  @override
  List<Object?> get props => [
    username,
    email,
    password,
    confirmPassword,
    firstName,
    lastName,
    birthDate,
    photoUrl,
    bio,
  ];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class AppleSignInRequested extends AuthEvent {
  const AppleSignInRequested();
}

class PasswordResetRequested extends AuthEvent {
  const PasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class ChangePasswordRequested extends AuthEvent {
  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class ProfileUpdateRequested extends AuthEvent {
  const ProfileUpdateRequested({
    required this.username,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.bio,
    this.photoUrl,
  });

  final String username;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? bio;
  final String? photoUrl;

  @override
  List<Object?> get props => [
    username,
    firstName,
    lastName,
    birthDate,
    bio,
    photoUrl,
  ];
}

class DeleteAccountRequested extends AuthEvent {
  const DeleteAccountRequested();
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
