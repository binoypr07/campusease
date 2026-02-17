import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Background Notification: ${message.notification?.title}");
}

class NotificationHandler {
  // ✅ Tracks which chat is open — instant, no Firestore delay
  static String? _activeChatId;

  static void setActiveChat(String? chatId) {
    _activeChatId = chatId;
    log("Active chat set to: $_activeChatId");
  }

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel',
      'General Notifications',
      description: 'CampusEase notifications',
      importance: Importance.max,
    );

    // ✅ FIXED syntax error from your original file
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation;
    AndroidFlutterLocalNotificationsPlugin()?.createNotificationChannel(
      channel,
    );
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'General Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? "CampusEase",
      message.notification?.body ?? "",
      notificationDetails,
    );
  }

  static void listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log("Foreground notification received: ${message.notification?.title}");
      log("Message data: ${message.data}");

      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      // ✅ FIX 1: Block sender's own notification
      final String? senderId = message.data['senderId'];
      if (senderId != null &&
          currentUserId != null &&
          senderId == currentUserId) {
        log("BLOCKED: Current user is the sender");
        return;
      }

      // ✅ FIX 2: Block if user is currently inside this chat
      final String? classId = message.data['classId'];
      if (classId != null && _activeChatId == classId) {
        log("BLOCKED: User is actively viewing this chat");
        return;
      }

      log("ALLOWED: Showing notification");
      await showLocalNotification(message);
    });
  }
}
