import 'dart:async';

import 'package:chat_app/src/features/auth/data/datasources/presence_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class PresenceLifecycleService with WidgetsBindingObserver {
  PresenceLifecycleService({
    required FirebaseAuth firebaseAuth,
    required UserRemoteDataSource userRemoteDataSource,
    required PresenceRemoteDataSource presenceRemoteDataSource,
  }) : _firebaseAuth = firebaseAuth,
       _userRemoteDataSource = userRemoteDataSource,
       _presenceRemoteDataSource = presenceRemoteDataSource;

  final FirebaseAuth _firebaseAuth;
  final UserRemoteDataSource _userRemoteDataSource;
  final PresenceRemoteDataSource _presenceRemoteDataSource;

  StreamSubscription<User?>? _authSub;
  bool _started = false;
  bool _updating = false;
  String? _activeUserId;
  AppLifecycleState? _lastLifecycleState;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _activeUserId = _firebaseAuth.currentUser?.uid;

    WidgetsBinding.instance.addObserver(this);
    await _setOnlineCurrentUser(setLastSeen: true);

    _authSub = _firebaseAuth.authStateChanges().listen(
      (user) => unawaited(_handleAuthChange(user)),
      onError: (_) {},
    );
  }

  Future<void> _handleAuthChange(User? user) async {
    final previousUserId = _activeUserId;
    final nextUserId = user?.uid;

    if (previousUserId != null && previousUserId != nextUserId) {
      await _setFirestorePresence(
        userId: previousUserId,
        isOnline: false,
        setLastSeen: true,
      );
    }

    _activeUserId = nextUserId;
    if (nextUserId != null) {
      await _setOnlineCurrentUser(setLastSeen: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    if (_lastLifecycleState == state) return;
    _lastLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      unawaited(_setOnlineCurrentUser(setLastSeen: true));
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_setOfflineCurrentUser());
    }
  }

  Future<void> _setOnlineCurrentUser({required bool setLastSeen}) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null || _updating) return;
    _updating = true;
    try {
      await Future.wait([
        _setFirestorePresence(
          userId: userId,
          isOnline: true,
          setLastSeen: setLastSeen,
        ),
        _presenceRemoteDataSource.setOnline(),
      ]);
    } catch (_) {
      // Presence should never crash app lifecycle handling.
    } finally {
      _updating = false;
    }
  }

  Future<void> _setOfflineCurrentUser() async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null || _updating) return;
    _updating = true;
    try {
      await Future.wait([
        _setFirestorePresence(
          userId: userId,
          isOnline: false,
          setLastSeen: true,
        ),
        _presenceRemoteDataSource.setOffline(),
      ]);
    } catch (_) {
      // Presence should never crash app lifecycle handling.
    } finally {
      _updating = false;
    }
  }

  Future<void> _setFirestorePresence({
    required String userId,
    required bool isOnline,
    required bool setLastSeen,
  }) {
    return _userRemoteDataSource.updatePresence(
      userId: userId,
      isOnline: isOnline,
      setLastSeen: setLastSeen,
    );
  }

  Future<void> dispose() async {
    if (!_started) return;
    WidgetsBinding.instance.removeObserver(this);
    await _authSub?.cancel();
    _authSub = null;
    _started = false;
  }
}
