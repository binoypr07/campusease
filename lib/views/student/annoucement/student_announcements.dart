import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String? classYear;
  String? department;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAndSetup();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load user data FIRST, then subscribe to the correct topics.
  // Original bug: _setupNotifications() was called in initState() before
  // classYear/department were loaded, so topic subscriptions were always null.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadAndSetup() async {
    final doc = await _db.collection("users").doc(uid).get();
    classYear = doc.data()?["classYear"];
    department = doc.data()?["department"];

    setState(() => loading = false);

    // Subscribe to topics only after data is loaded
    await _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    // Request permission (required for iOS, good practice for Android 13+)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Subscribe to department topic (e.g. "Computer_Science")
      if (department != null && department!.isNotEmpty) {
        await FirebaseMessaging.instance.subscribeToTopic(
          department!.replaceAll(' ', '_'),
        );
      }

      // Subscribe to class topic (e.g. "CS1")
      if (classYear != null && classYear!.isNotEmpty) {
        await FirebaseMessaging.instance.subscribeToTopic(
          classYear!.replaceAll(' ', '_'),
        );
      }

      // Subscribe to general "all" topic for college-wide announcements
      await FirebaseMessaging.instance.subscribeToTopic("all");
    }

    // Handle foreground notifications (app is open)
    // Mirrors the onMessage listener pattern used in GlobalChatScreen
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? "📢 Announcement",
          message.notification!.body ?? "",
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1F2C34),
          colorText: Colors.white,
          icon: const Icon(Icons.campaign, color: Colors.blueAccent),
          duration: const Duration(seconds: 4),
        );
      }
    });
  }

  bool _filter(Map<String, dynamic> d) {
    final t = d["target"];
    if (t == null) return false;
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection("announcements")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = snapshot.data!.docs
              .where((e) => _filter(e.data()))
              .toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("No announcements for your class"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final d = filtered[i].data();
              return Card(
                color: Colors.grey[900],
                child: ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.blueAccent),
                  title: Text(
                    d["title"] ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d["body"] ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (d["createdByName"] != null)
                        Text(
                          "By: ${d["createdByName"]}",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: d["createdByName"] != null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
