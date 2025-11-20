// lib/core/services/notification_service.dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background handler required by firebase_messaging.
/// Must be a top-level function (not inside a class).
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You can handle background messages here if needed.
  // Keep it minimal — avoid heavy async work.
  print('Background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Call this once (e.g. in main()) after Firebase.initializeApp()
  static Future<void> init() async {
    // Background handler registration
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions (iOS / web)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('FCM permission status: ${settings.authorizationStatus}');

    // Android: initialize flutter_local_notifications for foreground notifications
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // replace if needed
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _local.initialize(initSettings,
        onDidReceiveNotificationResponse: (payload) {
      // handle tap on local notification if you want
      print('local notification payload: $payload');
    });

    // Foreground message handling show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.messageId}');
      _showLocalNotification(message);
    });
  }

  /// Return the device token (may be null).
  static Future<String?> getToken() async {
    try {
      String? token = await _fcm.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('getToken error: $e');
      return null;
    }
  }

  /// Optional helper to show a simple local notification for foreground messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final android = notification.android;
    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'campusease_channel',
          'CampusEase Notifications',
          channelDescription: 'General notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  /// Optional: subscribe to a topic
  static Future<void> subscribeToTopic(String topic) =>
      _fcm.subscribeToTopic(topic);

  static Future<void> unsubscribeFromTopic(String topic) =>
      _fcm.unsubscribeFromTopic(topic);
}
