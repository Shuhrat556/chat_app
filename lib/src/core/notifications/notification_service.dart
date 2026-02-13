import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const _channelId = 'chat_messages_high_v2';
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
        _channelId,
        'Chat Messages',
        description: 'Incoming chat messages',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static bool _initialized = false;
  static bool _backgroundHandlerRegistered = false;
  static bool _localInitialized = false;
  static StreamSubscription<RemoteMessage>? _foregroundSub;

  static Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  static void registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) return;
    _backgroundHandlerRegistered = true;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      registerBackgroundHandler();
      await _initializeLocalNotifications(_local);
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen(_onMessage);
    } on MissingPluginException {
      // Plugin may be unavailable during a hot restart on desktop.
      _initialized = false;
    } catch (_) {
      // Keep app startup resilient if notifications fail to init.
      _initialized = false;
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
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final androidImplementation = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.requestNotificationsPermission();
      return settings;
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

  static Future<void> _initializeLocalNotifications(
    FlutterLocalNotificationsPlugin localPlugin,
  ) async {
    if (identical(localPlugin, _local) && _localInitialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await localPlugin.initialize(settings);

    final androidImplementation = localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannel(_chatChannel);
    if (identical(localPlugin, _local)) {
      _localInitialized = true;
    }
  }

  static Future<void> _onMessage(RemoteMessage message) async {
    await _showRemoteMessageAsLocal(
      message,
      localPlugin: _local,
      onlyDataPayload: false,
    );
  }

  static Future<void> _showRemoteMessageAsLocal(
    RemoteMessage message, {
    required FlutterLocalNotificationsPlugin localPlugin,
    required bool onlyDataPayload,
  }) async {
    if (onlyDataPayload && message.notification != null) {
      // System notification payload is already shown by OS in background.
      return;
    }

    final title = _extractTitle(message);
    final body = _extractBody(message);
    if (title == null && body == null) return;

    await _showLocalNotification(
      localPlugin: localPlugin,
      id: message.messageId?.hashCode ?? message.hashCode,
      title: title,
      body: body,
    );
  }

  static String? _extractTitle(RemoteMessage message) {
    return message.notification?.title ??
        _readString(message.data, 'title') ??
        _readString(message.data, 'senderName');
  }

  static String? _extractBody(RemoteMessage message) {
    return message.notification?.body ??
        _readString(message.data, 'body') ??
        _readString(message.data, 'text') ??
        _readString(message.data, 'message');
  }

  static String? _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static Future<void> _showLocalNotification({
    required FlutterLocalNotificationsPlugin localPlugin,
    required int id,
    required String? title,
    required String? body,
  }) async {
    final android = AndroidNotificationDetails(
      _chatChannel.id,
      _chatChannel.name,
      channelDescription: 'Incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'chat-message',
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: android, iOS: ios, macOS: ios);

    await localPlugin.show(id, title, body, details);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (_) {}

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  try {
    final localPlugin = FlutterLocalNotificationsPlugin();
    await NotificationService._initializeLocalNotifications(localPlugin);
    await NotificationService._showRemoteMessageAsLocal(
      message,
      localPlugin: localPlugin,
      onlyDataPayload: true,
    );
  } catch (_) {}
}
