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

  Future<void> updatePresence({
    required String userId,
    required bool isOnline,
    bool setLastSeen = false,
  }) {
    final data = <String, dynamic>{
      'isOnline': isOnline,
    };
    if (setLastSeen) {
      data['lastSeen'] = FieldValue.serverTimestamp();
    }
    return _firestore
        .collection(_userCollection)
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateUsernameReservation({
    String? previousUsername,
    required String newUsername,
    required String userId,
  }) async {
    final next = newUsername.trim().toLowerCase();
    final prev = previousUsername?.trim().toLowerCase();
    final newRef = _firestore.collection(_usernameCollection).doc(next);
    final prevRef = (prev != null && prev.isNotEmpty)
        ? _firestore.collection(_usernameCollection).doc(prev)
        : null;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(newRef);
      if (snap.exists && snap.data()?['userId'] != userId) {
        throw StateError('Username band');
      }
      tx.set(newRef, {
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (prevRef != null && prev != next) {
        final prevSnap = await tx.get(prevRef);
        if (prevSnap.exists && prevSnap.data()?['userId'] == userId) {
          tx.delete(prevRef);
        }
      }
    });
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

  Stream<AppUserModel?> streamUser(String userId) {
    return _firestore.collection(_userCollection).doc(userId).snapshots().map(
          (doc) => doc.exists ? AppUserModel.fromFirestore(doc) : null,
        );
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

  Future<void> deleteUser({required String userId}) async {
    final userRef = _firestore.collection(_userCollection).doc(userId);
    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      String? username;
      if (userSnap.exists) {
        final data = userSnap.data();
        username = data?['username'] as String?;
        tx.delete(userRef);
      }

      if (username != null && username.trim().isNotEmpty) {
        final normalized = username.trim().toLowerCase();
        final usernameRef =
            _firestore.collection(_usernameCollection).doc(normalized);
        final usernameSnap = await tx.get(usernameRef);
        if (usernameSnap.exists && usernameSnap.data()?['userId'] == userId) {
          tx.delete(usernameRef);
        }
      }
    });
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
