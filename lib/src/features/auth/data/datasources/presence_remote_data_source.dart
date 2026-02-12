import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceRemoteDataSource {
  PresenceRemoteDataSource(
    this._database,
    this._firebaseAuth,
  );

  final FirebaseDatabase _database;
  final FirebaseAuth _firebaseAuth;

  DatabaseReference _userRef(String uid) => _database.ref('status/$uid');

  Future<void> setOnline() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final ref = _userRef(uid);

    await ref.set({
      'state': 'online',
      'lastSeen': ServerValue.timestamp,
    });

    ref.onDisconnect().set({
      'state': 'offline',
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> setOffline() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final ref = _userRef(uid);
    await ref.set({
      'state': 'offline',
      'lastSeen': ServerValue.timestamp,
    });
  }

  Stream<PresenceStatus> watchPresence(String uid) {
    return _userRef(uid).onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final state = data['state'] as String?;
        final ts = data['lastSeen'];
        DateTime? lastSeen;
        if (ts is int) {
          lastSeen = DateTime.fromMillisecondsSinceEpoch(ts);
        }
        return PresenceStatus(
          isOnline: state == 'online',
          lastSeen: lastSeen,
        );
      }
      return const PresenceStatus(isOnline: false, lastSeen: null);
    });
  }
}

class PresenceStatus {
  const PresenceStatus({required this.isOnline, required this.lastSeen});

  final bool isOnline;
  final DateTime? lastSeen;
}
