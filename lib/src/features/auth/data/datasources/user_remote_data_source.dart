import 'package:chat_app/src/features/auth/data/models/app_user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRemoteDataSource {
  UserRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  static const _userCollection = 'users';
  static const _usernameCollection = 'usernames';

  Future<void> reserveUsername({
    required String username,
    required String userId,
  }) async {
    final normalized = username.trim().toLowerCase();
    final ref = _firestore.collection(_usernameCollection).doc(normalized);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists && snap.data()?['userId'] != userId) {
        throw StateError('Username band');
      }
      tx.set(ref, {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> saveUser(AppUserModel user) {
    return _firestore
        .collection(_userCollection)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> saveFcmToken({
    required String userId,
    required String? fcmToken,
  }) {
    return _firestore.collection(_userCollection).doc(userId).set({
      'fcmToken': fcmToken,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<AppUserModel?> fetchUser(String userId) async {
    final doc = await _firestore.collection(_userCollection).doc(userId).get();
    if (!doc.exists) return null;
    return AppUserModel.fromFirestore(doc);
  }

  Stream<List<AppUserModel>> streamUsers() {
    return _firestore
        .collection(_userCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUserModel.fromFirestore(doc))
              .toList(growable: false),
        );
  }

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection(_userCollection)
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }
}
