import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsRemoteDataSource {
  SettingsRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  static const _usersCollection = 'users';

  Future<UserSettings?> fetchSettings(String userId) async {
    final doc = await _firestore.collection(_usersCollection).doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final raw = data['settings'];
    if (raw is! Map) return null;
    return UserSettings.fromMap(Map<String, dynamic>.from(raw));
  }

  Stream<UserSettings?> watchSettings(String userId) {
    return _firestore.collection(_usersCollection).doc(userId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final raw = data['settings'];
      if (raw is! Map) return null;
      return UserSettings.fromMap(Map<String, dynamic>.from(raw));
    });
  }

  Future<void> saveSettings({
    required String userId,
    required UserSettings settings,
  }) {
    return _firestore.collection(_usersCollection).doc(userId).set({
      'settings': settings.toMap(),
      'settingsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
