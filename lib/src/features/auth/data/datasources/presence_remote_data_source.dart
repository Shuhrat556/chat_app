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

    await ref.onDisconnect().set({
      'state': 'offline',
      'lastSeen': ServerValue.timestamp,
    });
    await ref.set({'state': 'online', 'lastSeen': ServerValue.timestamp});
  }

  Future<void> setOffline() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final ref = _userRef(uid);
    await ref.onDisconnect().cancel();
    await ref.set({'state': 'offline', 'lastSeen': ServerValue.timestamp});
  }

  Future<void> setTyping(String conversationId, bool isTyping) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final ref = _database.ref('typing/$conversationId/$uid');

    if (isTyping) {
      await ref.onDisconnect().remove();
      await ref.set(ServerValue.timestamp);
    } else {
      await ref.remove();
    }
  }

  Stream<PresenceStatus> watchPresence(String uid) {
    return _userRef(uid).onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final stateRaw = data['state']?.toString().toLowerCase().trim();
        final ts = data['lastSeen'];
        final millis = _parseMillis(ts);
        final lastSeen = millis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(millis);
        return PresenceStatus(
          isOnline: stateRaw == 'online',
          lastSeen: lastSeen,
        );
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
            final key = entry.key.toString();
            if (key.isNotEmpty) {
              typingUsers.add(key);
            }
          }
        }
      }
      return typingUsers;
    });
  }

  int? _parseMillis(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}

class PresenceStatus {
  const PresenceStatus({required this.isOnline, required this.lastSeen});

  final bool isOnline;
  final DateTime? lastSeen;
}
