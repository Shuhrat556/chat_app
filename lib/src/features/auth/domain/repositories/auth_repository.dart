import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> signUp({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    String? photoUrl,
    String? bio,
  });

  /// Sends OTP to the given phone number (E.164 format, e.g. +992XXXXXXXXX).
  Future<String> sendPhoneOtp({
    required String phoneNumber,
    int? forceResendingToken,
  });

  /// Verifies OTP and signs in/creates user; optional username will be saved.
  Future<AppUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? username,
  });

  Future<void> signOut();

  Stream<AppUser?> authStateChanges();
}
