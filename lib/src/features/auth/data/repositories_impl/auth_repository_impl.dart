import 'dart:async';

import 'package:chat_app/src/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_local_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/presence_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/models/app_user_model.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/domain/validators/username_validator.dart';
import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDataSource authDataSource,
    required UserLocalDataSource userLocalDataSource,
    required UserRemoteDataSource userRemoteDataSource,
    required PresenceRemoteDataSource presenceRemoteDataSource,
    GoogleSignIn? googleSignIn,
  }) : _authDataSource = authDataSource,
       _userLocalDataSource = userLocalDataSource,
       _userRemoteDataSource = userRemoteDataSource,
       _presenceRemoteDataSource = presenceRemoteDataSource,
       _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuthDataSource _authDataSource;
  final UserLocalDataSource _userLocalDataSource;
  final UserRemoteDataSource _userRemoteDataSource;
  final PresenceRemoteDataSource _presenceRemoteDataSource;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AppUser?> authStateChanges() async* {
    await for (final firebaseUser in _authDataSource.authStateChanges()) {
      if (firebaseUser == null) {
        await _userLocalDataSource.clear();
        yield null;
        continue;
      }

      final cached = await _userLocalDataSource.fetchCachedUser(
        firebaseUser.uid,
      );
      if (cached != null) {
        yield cached;
      } else {
        final fallback = AppUserModel.fromFirebaseUser(firebaseUser);
        await _userLocalDataSource.saveUser(fallback);
        yield fallback;
      }

      try {
        final remote = await _userRemoteDataSource.fetchUser(firebaseUser.uid);
        final resolved = remote ?? AppUserModel.fromFirebaseUser(firebaseUser);
        if (remote == null) {
          await _userRemoteDataSource.saveUser(resolved);
        }
        await _userLocalDataSource.saveUser(resolved);
        unawaited(_markOnlineSafely(firebaseUser.uid));
        yield resolved;
      } catch (_) {
        // Offline: keep local cached session without interrupting auth stream.
      }
    }
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

    try {
      final remote = await _userRemoteDataSource.fetchUser(uid);
      if (remote != null) {
        await _userLocalDataSource.saveUser(remote);
        await _markOnlineSafely(uid);
        return remote;
      }
    } catch (_) {
      // Continue with local fallback below.
    }

    final userModel = AppUserModel.fromFirebaseUser(credential.user!);
    try {
      await _userRemoteDataSource.saveUser(userModel);
    } catch (_) {}
    await _userLocalDataSource.saveUser(userModel);
    await _markOnlineSafely(uid);
    return userModel;
  }

  @override
  Future<AppUser> signUp({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? photoUrl,
    String? bio,
  }) async {
    final usernameValidation = UsernameValidator.validate(username);
    if (usernameValidation != null) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message: usernameValidation.messageKey,
      );
    }
    final normalizedUsername = UsernameValidator.canonical(username);
    final cleanedFirstName = firstName?.trim();
    final cleanedLastName = lastName?.trim();
    final cleanedPhotoUrl = photoUrl?.trim();
    final cleanedBio = bio?.trim();

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
        message: e.message.isNotEmpty ? e.message : 'Bu username band',
      );
    }

    await firebaseUser.updateDisplayName(normalizedUsername);

    final userModel = AppUserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? email,
      username: normalizedUsername,
      firstName: cleanedFirstName == null || cleanedFirstName.isEmpty
          ? null
          : cleanedFirstName,
      lastName: cleanedLastName == null || cleanedLastName.isEmpty
          ? null
          : cleanedLastName,
      birthDate: birthDate,
      bio: cleanedBio == null || cleanedBio.isEmpty ? null : cleanedBio,
      photoUrl: cleanedPhotoUrl == null || cleanedPhotoUrl.isEmpty
          ? firebaseUser.photoURL
          : cleanedPhotoUrl,
      fcmToken: null,
      createdAt: DateTime.now(),
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await _userRemoteDataSource.saveUser(userModel);
    await _userLocalDataSource.saveUser(userModel);
    await _markOnlineSafely(firebaseUser.uid);
    return userModel;
  }

  @override
  Future<void> signOut() async {
    final uid = _authDataSource.currentUser?.uid;
    if (uid != null) {
      try {
        await Future.wait([
          _userRemoteDataSource.saveFcmToken(userId: uid, fcmToken: null),
          _userRemoteDataSource.updatePresence(
            userId: uid,
            isOnline: false,
            setLastSeen: true,
          ),
          _presenceRemoteDataSource.setOffline(),
        ]);
      } catch (_) {
        // Ignore network failures during local sign-out.
      }
    }
    await _authDataSource.signOut();
    await _userLocalDataSource.clear();
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-cancelled',
        message: 'Google bilan kirish bekor qilindi',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _authDataSource.signInWithCredential(credential);
    final firebaseUser = result.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'User credential not found',
      );
    }

    return _getOrCreateUserFromFirebaseUser(
      firebaseUser,
      preferredEmail: googleUser.email,
      preferredUsername:
          googleUser.displayName ?? googleUser.email.split('@').first,
      preferredPhoto: googleUser.photoUrl,
    );
  }

  @override
  Future<AppUser> signInWithApple() async {
    final appleIdCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    if (appleIdCredential.identityToken == null) {
      throw FirebaseAuthException(
        code: 'apple-no-token',
        message: 'Apple identity token topilmadi',
      );
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleIdCredential.identityToken,
      accessToken: appleIdCredential.authorizationCode,
    );

    final result = await _authDataSource.signInWithCredential(oauthCredential);
    final firebaseUser = result.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'User credential not found',
      );
    }

    final displayName = [
      appleIdCredential.givenName,
      appleIdCredential.familyName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

    return _getOrCreateUserFromFirebaseUser(
      firebaseUser,
      preferredEmail: appleIdCredential.email,
      preferredUsername: displayName.isNotEmpty
          ? displayName
          : appleIdCredential.email ?? 'apple_user',
      firstName: appleIdCredential.givenName,
      lastName: appleIdCredential.familyName,
    );
  }

  @override
  Future<void> sendPasswordReset({required String email}) {
    return _authDataSource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _authDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<AppUser> updateProfile({
    required String username,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? bio,
    String? photoUrl,
  }) async {
    final firebaseUser = _authDataSource.currentUser;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'User credential not found',
      );
    }

    AppUser? current;
    try {
      current = await _userRemoteDataSource.fetchUser(firebaseUser.uid);
    } catch (_) {
      // Continue with Firebase-auth fallback values below.
    }
    final currentUsername = current?.username ?? firebaseUser.displayName ?? '';
    final usernameValidation = UsernameValidator.validate(username);
    if (usernameValidation != null) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message: usernameValidation.messageKey,
      );
    }
    final normalizedUsername = UsernameValidator.canonical(username);

    if (normalizedUsername.toLowerCase() !=
        currentUsername.trim().toLowerCase()) {
      try {
        await _userRemoteDataSource.updateUsernameReservation(
          previousUsername: currentUsername.isEmpty ? null : currentUsername,
          newUsername: normalizedUsername,
          userId: firebaseUser.uid,
        );
      } on StateError catch (e) {
        throw FirebaseAuthException(
          code: 'username-taken',
          message: e.message.isNotEmpty ? e.message : 'Bu username band',
        );
      }
    }

    final cleanedFirstName = firstName?.trim();
    final cleanedLastName = lastName?.trim();
    final cleanedBio = bio?.trim();
    final cleanedPhoto = photoUrl?.trim();

    await _authDataSource.updateProfile(
      displayName: normalizedUsername,
      photoUrl: cleanedPhoto?.isNotEmpty == true
          ? cleanedPhoto
          : (current?.photoUrl ?? firebaseUser.photoURL),
    );

    final updatedUser = AppUserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? current?.email ?? '',
      username: normalizedUsername,
      firstName: cleanedFirstName == null
          ? current?.firstName
          : cleanedFirstName.isEmpty
          ? null
          : cleanedFirstName,
      lastName: cleanedLastName == null
          ? current?.lastName
          : cleanedLastName.isEmpty
          ? null
          : cleanedLastName,
      birthDate: birthDate ?? current?.birthDate,
      bio: cleanedBio == null
          ? current?.bio
          : cleanedBio.isEmpty
          ? null
          : cleanedBio,
      photoUrl: cleanedPhoto == null
          ? current?.photoUrl
          : cleanedPhoto.isEmpty
          ? null
          : cleanedPhoto,
      fcmToken: current?.fcmToken,
      createdAt: current?.createdAt ?? firebaseUser.metadata.creationTime,
      phone: firebaseUser.phoneNumber ?? current?.phone,
      isOnline: current?.isOnline,
      lastSeen: current?.lastSeen,
    );

    await _userRemoteDataSource.saveUser(updatedUser);
    await _userLocalDataSource.saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<void> deleteAccount() async {
    final firebaseUser = _authDataSource.currentUser;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'User credential not found',
      );
    }
    await _userRemoteDataSource.deleteUser(userId: firebaseUser.uid);
    await _authDataSource.deleteAccount();
    await _userLocalDataSource.clear();
  }

  Future<AppUser> _getOrCreateUserFromFirebaseUser(
    User firebaseUser, {
    String? preferredEmail,
    String? preferredUsername,
    String? preferredPhoto,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final remote = await _userRemoteDataSource.fetchUser(firebaseUser.uid);
      if (remote != null) {
        await _userLocalDataSource.saveUser(remote);
        await _markOnlineSafely(firebaseUser.uid);
        return remote;
      }
    } catch (_) {
      // Continue with creation flow below.
    }

    final normalizedUsername = await _reserveUsername(
      userId: firebaseUser.uid,
      desired:
          preferredUsername ??
          firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          _lettersFallbackFromSeed(firebaseUser.uid),
    );

    await firebaseUser.updateDisplayName(normalizedUsername);

    final userModel = AppUserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? preferredEmail ?? '',
      username: normalizedUsername,
      firstName: firstName ?? firebaseUser.displayName,
      lastName: lastName,
      birthDate: null,
      bio: null,
      photoUrl: preferredPhoto ?? firebaseUser.photoURL,
      fcmToken: null,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      phone: firebaseUser.phoneNumber,
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await _userRemoteDataSource.saveUser(userModel);
    await _userLocalDataSource.saveUser(userModel);
    await _markOnlineSafely(firebaseUser.uid);
    return userModel;
  }

  Future<String> _reserveUsername({
    required String userId,
    required String desired,
  }) async {
    var candidate = _normalizeUsername(desired);
    if (candidate.length < 5) {
      candidate = (candidate + _lettersFallbackFromSeed(userId)).substring(
        0,
        5,
      );
    }
    if (candidate.length > 20) {
      candidate = candidate.substring(0, 20);
    }
    try {
      await _userRemoteDataSource.reserveUsername(
        username: candidate,
        userId: userId,
      );
      return candidate;
    } on StateError {
      final fallbackSeed = _lettersFallbackFromSeed(
        '$candidate${DateTime.now().microsecondsSinceEpoch}',
      );
      final fallbackLength = (candidate.length + fallbackSeed.length)
          .clamp(5, 20)
          .toInt();
      final fallback = (candidate + fallbackSeed).substring(0, fallbackLength);
      await _userRemoteDataSource.reserveUsername(
        username: fallback,
        userId: userId,
      );
      return fallback;
    }
  }

  String _normalizeUsername(String value) {
    final cleaned = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    if (cleaned.isNotEmpty) return cleaned;
    return _lettersFallbackFromSeed(value);
  }

  String _lettersFallbackFromSeed(String seed) {
    final source = seed.isEmpty ? 'userseed' : seed;
    final buffer = StringBuffer('user');
    for (var i = 0; i < source.length && buffer.length < 8; i++) {
      final code = source.codeUnitAt(i);
      final letter = String.fromCharCode(97 + (code % 26));
      buffer.write(letter);
    }
    while (buffer.length < 5) {
      buffer.write('x');
    }
    return buffer.toString();
  }

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

    final provided = username?.trim() ?? '';
    final fallbackUsername = _lettersFallbackFromSeed(firebaseUser.uid);
    String normalizedUsername = provided.isNotEmpty
        ? UsernameValidator.canonical(provided)
        : fallbackUsername;

    // Reserve if provided explicitly to avoid collision.
    if (provided.isNotEmpty) {
      final validation = UsernameValidator.validate(provided);
      if (validation != null) {
        throw FirebaseAuthException(
          code: 'invalid-username',
          message: validation.messageKey,
        );
      }
      try {
        await _userRemoteDataSource.reserveUsername(
          username: normalizedUsername,
          userId: firebaseUser.uid,
        );
      } on StateError catch (e) {
        throw FirebaseAuthException(
          code: 'username-taken',
          message: e.message.isNotEmpty ? e.message : 'Bu username band',
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
        normalizedUsername = await _reserveUsername(
          userId: firebaseUser.uid,
          desired: fallbackUsername,
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
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await _userRemoteDataSource.saveUser(userModel);
    await _userLocalDataSource.saveUser(userModel);
    await _markOnlineSafely(firebaseUser.uid);
    return userModel;
  }

  Future<void> _markOnline(String uid) async {
    await Future.wait([
      _userRemoteDataSource.updatePresence(
        userId: uid,
        isOnline: true,
        setLastSeen: true,
      ),
      _presenceRemoteDataSource.setOnline(),
    ]);
  }

  Future<void> _markOnlineSafely(String uid) async {
    try {
      await _markOnline(uid);
    } catch (_) {
      // Ignore network failures for non-critical presence updates.
    }
  }
}
