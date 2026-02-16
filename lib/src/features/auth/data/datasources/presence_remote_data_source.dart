import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceRemoteDataSource {
  PresenceRemoteDataSource(this._database, this._firebaseAuth);

  final FirebaseDatabase _database;
  final FirebaseAuth _firebaseAuth;

  DatabaseReference _userRef(String uid) => _database.ref('status/$uid');

  Future<void> setOnline() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final ref = _userRef(uid);

    await ref.set({'state': 'online', 'lastSeen': ServerValue.timestamp});

    ref.onDisconnect().set({
      'state': 'offline',
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> setOffline() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final ref = _userRef(uid);
    await ref.set({'state': 'offline', 'lastSeen': ServerValue.timestamp});
  }

  Future<void> setTyping(String conversationId, bool isTyping) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final ref = _database.ref('typing/$conversationId/$uid');

    if (isTyping) {
      await ref.set(ServerValue.timestamp);
      ref.onDisconnect().remove();
    } else {
      await ref.remove();
    }
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
        return PresenceStatus(isOnline: state == 'online', lastSeen: lastSeen);
      }
      return const PresenceStatus(isOnline: false, lastSeen: null);
    });
  }

  Stream<Set<String>> watchTypingUsers(String conversationId) {
    return _database.ref('typing/$conversationId').onValue.map((event) {
      final data = event.snapshot.value;
      final typingUsers = <String>{};
      if (data is Map) {
        for (final entry in data.entries) {
          if (entry.value != null) {
            typingUsers.add(entry.key as String);
          }
        }
      }
      return typingUsers;
    });
  }
}

class PresenceStatus {
  const PresenceStatus({required this.isOnline, required this.lastSeen});

  final bool isOnline;
  final DateTime? lastSeen;
}
