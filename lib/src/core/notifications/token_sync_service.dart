import 'dart:async';

import 'package:chat_app/src/core/notifications/notification_service.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TokenSyncService {
  TokenSyncService(this._remoteDataSource, this._firebaseAuth);

  final UserRemoteDataSource _remoteDataSource;
  final FirebaseAuth _firebaseAuth;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _listening = false;

  void startListening() {
    if (_listening) return;
    _listening = true;
    _tokenRefreshSub = NotificationService.onTokenRefresh.listen(
      (token) => _saveToken(token),
      onError: (_) {},
    );
  }

  Future<void> syncCurrentUserToken() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final token = await NotificationService.getToken();
    await _remoteDataSource.saveFcmToken(userId: uid, fcmToken: token);
  }

  Future<void> _saveToken(String token) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    await _remoteDataSource.saveFcmToken(userId: uid, fcmToken: token);
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _listening = false;
  }
}
