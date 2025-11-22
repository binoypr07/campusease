import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // -------------------------------------------------------------
  // INIT — Call once at app startup
  // -------------------------------------------------------------
  static Future<void> initialize() async {
    // Request permissions (Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _local.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? "Notification",
          body: message.notification!.body ?? "",
        );
      }
    });
  }

  // -------------------------------------------------------------
  // SHOW LOCAL NOTIFICATION (foreground)
  // -------------------------------------------------------------
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_channel',
      'High Priority Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _local.show(1, title, body, details);
  }

  // -------------------------------------------------------------
  // GET DEVICE TOKEN
  // -------------------------------------------------------------
  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
