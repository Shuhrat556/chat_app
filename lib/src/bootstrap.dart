import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/src/app.dart';
import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/core/logger/app_bloc_observer.dart';
import 'package:chat_app/src/core/notifications/notification_service.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// App entrypoint: initializes Firebase and DI, then runs the widget tree.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error hooks.
  Bloc.observer = AppBlocObserver();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Uncaught] $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      await Firebase.initializeApp();
      break;
    default:
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
  }

  await configureDependencies();
  await NotificationService.initialize();

  runApp(const App());
}
