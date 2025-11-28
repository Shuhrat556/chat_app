import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/src/app.dart';
import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/core/notifications/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// App entrypoint: initializes Firebase and DI, then runs the widget tree.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await configureDependencies();
  await NotificationService.initialize();

  runApp(const App());
}
