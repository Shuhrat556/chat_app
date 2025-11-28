import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase config extracted from android/app/google-services.json.
/// For iOS/Web later qo'shish kerak; hozircha Androidni qo'llaydi.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnimplementedError('Web Firebase konfiguratsiyasini qo\'shing.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnimplementedError(
          'Ushbu platforma uchun Firebase konfiguratsiyasini qo\'shing.',
        );
      case TargetPlatform.fuchsia:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDyTea4ud-8dJFPR1hugk73BjxgqUQjBcI',
    appId: '1:379129318878:android:c7a4a5562aaab7ed29614f',
    messagingSenderId: '379129318878',
    projectId: 'chat-app-9afab',
    storageBucket: 'chat-app-9afab.firebasestorage.app',
  );
}
