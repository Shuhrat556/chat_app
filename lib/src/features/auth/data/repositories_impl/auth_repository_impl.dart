import 'package:chat_app/src/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/models/app_user_model.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDataSource authDataSource,
    required UserRemoteDataSource userRemoteDataSource,
  })  : _authDataSource = authDataSource,
        _userRemoteDataSource = userRemoteDataSource;

  final FirebaseAuthDataSource _authDataSource;
  final UserRemoteDataSource _userRemoteDataSource;

  @override
  Stream<AppUser?> authStateChanges() {
    return _authDataSource.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final remote = await _userRemoteDataSource.fetchUser(user.uid);
      return remote ?? AppUserModel.fromFirebaseUser(user);
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _authDataSource.signIn(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'User credential not found',
      );
    }

    final remote = await _userRemoteDataSource.fetchUser(uid);
    return remote ?? AppUserModel.fromFirebaseUser(credential.user!);
  }

  @override
  Future<AppUser> signUp({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    String? photoUrl,
  }) async {
    final normalizedUsername = username.trim();

    final credential = await _authDataSource.signUp(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'User credential not found',
      );
    }

    try {
      await _userRemoteDataSource.reserveUsername(
        username: normalizedUsername,
        userId: firebaseUser.uid,
      );
    } on StateError catch (e) {
      await firebaseUser.delete();
      throw FirebaseAuthException(
        code: 'username-taken',
        message: e.message ?? 'Bu username band',
      );
    }

    await firebaseUser.updateDisplayName(normalizedUsername);

    final userModel = AppUserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? email,
      username: normalizedUsername,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      photoUrl: photoUrl ?? firebaseUser.photoURL,
      fcmToken: null,
      createdAt: DateTime.now(),
    );

    await _userRemoteDataSource.saveUser(userModel);
    return userModel;
  }

  @override
  Future<void> signOut() => _authDataSource.signOut();

  @override
  Future<String> sendPhoneOtp({
    required String phoneNumber,
    int? forceResendingToken,
  }) {
    return _authDataSource.sendPhoneOtp(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
    );
  }

  @override
  Future<AppUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? username,
  }) async {
    final credential = await _authDataSource.signInWithSmsCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'User credential not found',
      );
    }

    // Use provided username or fallback.
    final phoneDigits =
        (firebaseUser.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');
    final fallbackUsername = phoneDigits.isNotEmpty
        ? 'tg_${phoneDigits.length >= 4 ? phoneDigits.substring(phoneDigits.length - 4) : phoneDigits}'
        : 'tg_user';
    String normalizedUsername = (username?.trim().isNotEmpty ?? false)
        ? username!.trim()
        : fallbackUsername;

    // Reserve if provided explicitly to avoid collision.
    if (username != null && username.trim().isNotEmpty) {
      try {
        await _userRemoteDataSource.reserveUsername(
          username: normalizedUsername,
          userId: firebaseUser.uid,
        );
      } on StateError catch (e) {
        throw FirebaseAuthException(
          code: 'username-taken',
          message: e.message ?? 'Bu username band',
        );
      }
    } else {
      // Try to reserve fallback; if band bo'lsa, uniq qo'shib qayta urinish.
      try {
        await _userRemoteDataSource.reserveUsername(
          username: normalizedUsername,
          userId: firebaseUser.uid,
        );
      } on StateError {
        normalizedUsername = '${fallbackUsername}_${DateTime.now().millisecondsSinceEpoch % 10000}';
        await _userRemoteDataSource.reserveUsername(
          username: normalizedUsername,
          userId: firebaseUser.uid,
        );
      }
    }

    await firebaseUser.updateDisplayName(normalizedUsername);

    final userModel = AppUserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username: normalizedUsername,
      photoUrl: firebaseUser.photoURL,
      fcmToken: null,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      phone: firebaseUser.phoneNumber,
    );

    await _userRemoteDataSource.saveUser(userModel);
    return userModel;
  }
}
