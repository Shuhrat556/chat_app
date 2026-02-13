import 'package:chat_app/src/core/notifications/notification_service.dart';
import 'package:chat_app/src/bootstrap.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.registerBackgroundHandler();
  await bootstrap();
}
