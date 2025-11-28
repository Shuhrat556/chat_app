import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Notifications temporarily disabled to avoid MissingPluginException.
    return;
  }

  static Future<String?> getToken() async => null;

  static Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } on MissingPluginException {
      // Hot reload after adding plugin; skip to avoid crash.
    }
  }

  static Future<void> _onMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _showLocalNotification(notification);
  }

  static Future<void> _showLocalNotification(
    RemoteNotification notification,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  final notification = message.notification;
  if (notification == null) return;
  const androidDetails = AndroidNotificationDetails(
    'chat_messages',
    'Chat Messages',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );
  const details = NotificationDetails(android: androidDetails);
  await NotificationService._local.show(
    notification.hashCode,
    notification.title,
    notification.body,
    details,
  );
}
