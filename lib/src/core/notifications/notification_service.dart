import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        description: 'Incoming chat messages',
        importance: Importance.high,
      );

  static bool _initialized = false;
  static StreamSubscription<RemoteMessage>? _foregroundSub;

  static Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      await _initializeLocalNotifications();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _foregroundSub = FirebaseMessaging.onMessage.listen(_onMessage);
    } on MissingPluginException {
      // Plugin may be unavailable during a hot restart on desktop.
    } catch (_) {
      // Keep app startup resilient if notifications fail to init.
    }
  }

  static Future<String?> getToken() async {
    try {
      return _messaging.getToken();
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<NotificationSettings?> requestPermissionAfterAuth() async {
    try {
      return _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> dispose() async {
    await _foregroundSub?.cancel();
    _foregroundSub = null;
    _initialized = false;
  }

  static Future<void> _initializeLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _local.initialize(settings);

    final androidImplementation = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannel(_chatChannel);
  }

  static Future<void> _onMessage(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;
    await _showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
    );
  }

  static Future<void> _showLocalNotification({
    required int id,
    required String? title,
    required String? body,
  }) async {
    const android = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Incoming chat messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: android, iOS: ios, macOS: ios);

    await _local.show(id, title, body, details);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  final title = message.notification?.title ?? message.data['title'] as String?;
  final body = message.notification?.body ?? message.data['body'] as String?;
  if (title == null && body == null) return;

  const android = AndroidNotificationDetails(
    'chat_messages',
    'Chat Messages',
    channelDescription: 'Incoming chat messages',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );
  const ios = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const details = NotificationDetails(android: android, iOS: ios, macOS: ios);

  await FlutterLocalNotificationsPlugin().show(
    message.hashCode,
    title,
    body,
    details,
  );
}
