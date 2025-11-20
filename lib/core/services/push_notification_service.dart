import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class PushNotificationService {
  static final FirebaseMessaging _fm = FirebaseMessaging.instance;

  // LOCAL notification plugin
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // ---- INITIALIZE ----
  static Future<void> initialize() async {
    // ask permission
    await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // init local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    // foreground notifications
    FirebaseMessaging.onMessage.listen((event) {
      showLocalNotification(
        event.notification?.title ?? "Notification",
        event.notification?.body ?? "",
      );
    });
  }

  // ---- SHOW LOCAL NOTIFICATION ----
  static Future<void> showLocalNotification(String title, String body) async {
    const android = AndroidNotificationDetails(
      'campus_channel',
      'CampusEase Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: android);

    await _local.show(0, title, body, details);
  }

  // ---- GET DEVICE TOKEN ----
  static Future<String?> getToken() async {
    return await _fm.getToken();
  }

  // ---- SEND PUSH NOTIFICATION ----
  static Future<void> sendPushNotification({
    required List<String> tokens,
    required String title,
    required String body,
  }) async {
    const String serverKey =
        "AAAANAuP4wY:APA91bGR9vTH..." 
        // ← BRO replace with your own FCM server key from Firebase Console

    final url = Uri.parse("https://fcm.googleapis.com/fcm/send");

    for (String token in tokens) {
      await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "key=$serverKey"
        },
        body: jsonEncode({
          "to": token,
          "notification": {
            "title": title,
            "body": body,
          },
        }),
      );
    }
  }
}
