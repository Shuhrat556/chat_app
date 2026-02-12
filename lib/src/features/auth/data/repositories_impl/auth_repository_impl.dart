import 'package:chat_app/src/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/presence_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/models/app_user_model.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDataSource authDataSource,
    required UserRemoteDataSource userRemoteDataSource,
    required PresenceRemoteDataSource presenceRemoteDataSource,
    GoogleSignIn? googleSignIn,
  })  : _authDataSource = authDataSource,
        _userRemoteDataSource = userRemoteDataSource,
        _presenceRemoteDataSource = presenceRemoteDataSource,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuthDataSource _authDataSource;
  final UserRemoteDataSource _userRemoteDataSource;
  final PresenceRemoteDataSource _presenceRemoteDataSource;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AppUser?> authStateChanges() {
    return _authDataSource.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final remote = await _userRemoteDataSource.fetchUser(user.uid);
      if (remote != null) {
        await _markOnline(user.uid);
        return remote;
      }
      final fallback = AppUserModel.fromFirebaseUser(user);
      await _userRemoteDataSource.saveUser(fallback);
      await _markOnline(user.uid);
      return fallback;
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
    if (remote != null) {
      await _markOnline(uid);
      return remote;
    }

    final userModel = AppUserModel.fromFirebaseUser(credential.user!);
    await _userRemoteDataSource.saveUser(userModel);
    await _markOnline(uid);
    return userModel;
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
    String? bio,
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
        message: e.message.isNotEmpty ? e.message : 'Bu username band',
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
      bio: bio,
      photoUrl: photoUrl ?? firebaseUser.photoURL,
      fcmToken: null,
      createdAt: DateTime.now(),
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await _userRemoteDataSource.saveUser(userModel);
    await _markOnline(firebaseUser.uid);
    return userModel;
  }

  @override
  Future<void> signOut() async {
    final uid = _authDataSource.currentUser?.uid;
    if (uid != null) {
      await Future.wait([
        _userRemoteDataSource.updatePresence(
          userId: uid,
          isOnline: false,
          setLastSeen: true,
        ),
        _presenceRemoteDataSource.setOffline(),
      ]);
    }
    await _authDataSource.signOut();
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
      preferredUsername: googleUser.displayName ?? googleUser.email.split('@').first,
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

    final current = await _userRemoteDataSource.fetchUser(firebaseUser.uid);
    final currentUsername = current?.username ?? firebaseUser.displayName ?? '';
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message: 'Username bo\'sh bo\'lishi mumkin emas',
      );
    }

    if (normalizedUsername != currentUsername) {
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
      firstName:
          cleanedFirstName == null ? current?.firstName : cleanedFirstName.isEmpty ? null : cleanedFirstName,
      lastName:
          cleanedLastName == null ? current?.lastName : cleanedLastName.isEmpty ? null : cleanedLastName,
      birthDate: birthDate ?? current?.birthDate,
      bio: cleanedBio == null ? current?.bio : cleanedBio.isEmpty ? null : cleanedBio,
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
  }

  Future<AppUser> _getOrCreateUserFromFirebaseUser(
    User firebaseUser, {
    String? preferredEmail,
    String? preferredUsername,
    String? preferredPhoto,
    String? firstName,
    String? lastName,
  }) async {
    final remote = await _userRemoteDataSource.fetchUser(firebaseUser.uid);
    if (remote != null) {
      await _markOnline(firebaseUser.uid);
      return remote;
    }

    final normalizedUsername = await _reserveUsername(
      userId: firebaseUser.uid,
      desired: preferredUsername ??
          firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'user_${firebaseUser.uid.substring(0, 6)}',
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
    await _markOnline(firebaseUser.uid);
    return userModel;
  }

  Future<String> _reserveUsername({
    required String userId,
    required String desired,
  }) async {
    var candidate = _normalizeUsername(desired);
    if (candidate.length < 3) {
      candidate = '${candidate}_${DateTime.now().millisecondsSinceEpoch % 1000}';
    }
    try {
      await _userRemoteDataSource.reserveUsername(
        username: candidate,
        userId: userId,
      );
      return candidate;
    } on StateError {
      final fallback =
          '${candidate}_${DateTime.now().millisecondsSinceEpoch % 10000}';
      await _userRemoteDataSource.reserveUsername(
        username: fallback,
        userId: userId,
      );
      return fallback;
    }
  }

  String _normalizeUsername(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    if (cleaned.isNotEmpty) return cleaned;
    return 'user';
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
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await _userRemoteDataSource.saveUser(userModel);
    await _markOnline(firebaseUser.uid);
    return userModel;
  }

  Future<void> _markOnline(String uid) {
    return Future.wait([
      _userRemoteDataSource.updatePresence(
        userId: uid,
        isOnline: true,
        setLastSeen: true,
      ),
      _presenceRemoteDataSource.setOnline(),
    ]);
  }
}
