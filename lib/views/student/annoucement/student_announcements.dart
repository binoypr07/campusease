import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Add this
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance; // Instance for FCM
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String? classYear;
  String? department;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
    _setupNotifications(); // Initialize notification listeners
  }

  // 1. Setup Notification Permissions and Topic Subscriptions
  Future<void> _setupNotifications() async {
    // Request permission (Required for iOS, good practice for Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Once data is loaded, subscribe to topics
      if (department != null) {
        await _fcm.subscribeToTopic(department!.replaceAll(' ', '_'));
      }
      if (classYear != null) {
        await _fcm.subscribeToTopic(classYear!.replaceAll(' ', '_'));
      }
      // General topic for all students
      await _fcm.subscribeToTopic("all");
    }

    // Handle foreground notifications (while the app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? "Announcement",
          message.notification!.body ?? "",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blueAccent,
          colorText: Colors.white,
        );
      }
    });
  }

  Future<void> load() async {
    var doc = await _db.collection("users").doc(uid).get();
    classYear = doc["classYear"];
    department = doc["department"];

    // Re-trigger notification setup now that we have the class/dept info
    _setupNotifications();

    setState(() => loading = false);
  }

  bool _filter(Map<String, dynamic> d) {
    var t = d["target"];
    if (t["type"] == "all") return true;
    if (t["type"] == "department" && t["value"] == department) return true;
    if (t["type"] == "class" && t["value"] == classYear) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
      body: StreamBuilder(
        stream: _db
            .collection("announcements")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var filtered = snapshot.data!.docs
              .where((e) => _filter(e.data()))
              .toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("No announcements for your class"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              var d = filtered[i].data();
              return Card(
                color: Colors.grey[900], // Dark theme to match teacher UI
                child: ListTile(
                  title: Text(
                    d["title"] ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    d["body"] ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  leading: const Icon(Icons.campaign, color: Colors.blue),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
