import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  static final FirebaseMessaging _fm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // ----------------------------------------------------------
  // INITIALIZE NOTIFICATION SYSTEM
  // ----------------------------------------------------------
  static Future<void> initialize() async {
    // Request permission (Android 13+ & iOS)
    NotificationSettings settings = await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("NOTIFICATION PERMISSION: ${settings.authorizationStatus}");

    // Setup local notification channel for foreground notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important notifications.',
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize local notifications
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);

    await _local.initialize(initSettings);

    // FOREGROUND MESSAGE HANDLER
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("FOREGROUND MESSAGE: ${message.notification?.title}");

      _local.show(
        message.hashCode,
        message.notification?.title ?? "New Message",
        message.notification?.body ?? "",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
          ),
        ),
      );
    });

    // BACKGROUND MESSAGE HANDLER
    FirebaseMessaging.onBackgroundMessage(_firebaseBgHandler);
  }

  // ----------------------------------------------------------
  // GET USER TOKEN
  // ----------------------------------------------------------
  static Future<String?> getToken() async {
    return await _fm.getToken();
  }
}

// Background handler must be a TOP-LEVEL FUNCTION
@pragma('vm:entry-point')
Future<void> _firebaseBgHandler(RemoteMessage message) async {
  print("BACKGROUND MESSAGE: ${message.notification?.title}");
}
