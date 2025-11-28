import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/notifications/notification_service.dart';

class TokenSyncService {
  TokenSyncService(this._remoteDataSource, this._firebaseAuth);

  final UserRemoteDataSource _remoteDataSource;
  final FirebaseAuth _firebaseAuth;

  Future<void> syncCurrentUserToken() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final token = await NotificationService.getToken();
    await _remoteDataSource.saveFcmToken(userId: uid, fcmToken: token);
  }
}
