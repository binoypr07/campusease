import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSender {
  static const String serverKey = "YOUR_SERVER_KEY_HERE"; // Replace

  static Future<void> sendToTokens({
    required List<String> tokens,
    required String title,
    required String body,
  }) async {
    if (tokens.isEmpty) return;

    final url = Uri.parse("https://fcm.googleapis.com/fcm/send");

    for (String token in tokens) {
      await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "key=$serverKey",
        },
        body: jsonEncode({
          "to": token,
          "notification": {
            "title": title,
            "body": body,
            "sound": "default",
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "screen": "announcements",
          }
        }),
      );
    }
  }

  // ADMIN → send to ALL teachers & students
  static Future<void> sendToAll({
    required String title,
    required String body,
  }) async {
    var snap = await FirebaseFirestore.instance.collection("users").get();
    List<String> tokens = [];

    for (var doc in snap.docs) {
      if (doc["fcmToken"] != null && doc["fcmToken"].toString().isNotEmpty) {
        tokens.add(doc["fcmToken"]);
      }
    }

    await sendToTokens(tokens: tokens, title: title, body: body);
  }

  // TEACHER → send to own department
  static Future<void> sendToDepartment({
    required String department,
    required String title,
    required String body,
  }) async {
    var snap = await FirebaseFirestore.instance
        .collection("users")
        .where("department", isEqualTo: department)
        .get();

    List<String> tokens = [];
    for (var doc in snap.docs) {
      if (doc["fcmToken"] != null && doc["fcmToken"] != "") {
        tokens.add(doc["fcmToken"]);
      }
    }

    await sendToTokens(tokens: tokens, title: title, body: body);
  }

  // TEACHER → send to assigned class
  static Future<void> sendToClass({
    required String classYear,
    required String title,
    required String body,
  }) async {
    var snap = await FirebaseFirestore.instance
        .collection("users")
        .where("classYear", isEqualTo: classYear)
        .get();

    List<String> tokens = [];
    for (var doc in snap.docs) {
      if (doc["fcmToken"] != null && doc["fcmToken"] != "") {
        tokens.add(doc["fcmToken"]);
      }
    }

    await sendToTokens(tokens: tokens, title: title, body: body);
  }
}
