import 'dart:async';

import 'package:flutter/foundation.dart';

/// Minimal `ChangeNotifier` that listens to a stream and notifies GoRouter to rebuild.
class StreamRefreshListenable extends ChangeNotifier {
  StreamRefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
