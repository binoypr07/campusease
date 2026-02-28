import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class TeacherAnnouncementsScreen extends StatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  State<TeacherAnnouncementsScreen> createState() =>
      _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState
    extends State<TeacherAnnouncementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String? teacherDept;
  String? teacherClass;
  String? teacherName;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final doc = await _db.collection("users").doc(uid).get();
    teacherDept = doc.data()?["department"];
    teacherClass = doc.data()?["assignedClass"];
    teacherName = doc.data()?["name"] ?? "Teacher";

    if (teacherDept != null) {
      final deptTopic = teacherDept!.replaceAll(' ', '_');
      await FirebaseMessaging.instance.subscribeToTopic(deptTopic);
    }
    if (teacherClass != null) {
      final classTopic = teacherClass!.replaceAll(' ', '_');
      await FirebaseMessaging.instance.subscribeToTopic(classTopic);
    }

    setState(() => loading = false);
  }

  Future<void> _wakeUpRenderServer() async {
    final url = Uri.parse('https://shade-0pxb.onrender.com/users');
    try {
      await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "shade-key": "",
            },
            body: jsonEncode({
              "sender": "System_Wakeup",
              "text": "Announcement_Entry",
              "classId": teacherClass ?? teacherDept ?? "",
              "time": DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print("Render wakeup: Server waking up or offline. (Ignoring)");
    }
  }

  Future<void> _sendAnnouncementNotification({
    required String title,
    required String body,
    required String targetTopic,
  }) async {
    final String fcmTopic = targetTopic.replaceAll(' ', '_');

    final url = Uri.parse('https://shade-0pxb.onrender.com/notification');
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "from": "CampusEase",
          "to": "/topics/$fcmTopic",
          "title": "📢 $title",
          "body": "${teacherName ?? 'Teacher'}: $body",
          "data": {
            "type": "announcement",
            "targetTopic": targetTopic,
            "senderId": uid,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          },
        }),
      );
      print("Announcement notification sent to topic: $fcmTopic");
    } catch (e) {
      print("Failed to send announcement notification: $e");
    }
  }

  Future<void> _createAnnouncement() async {
    _wakeUpRenderServer();

    final titleC = TextEditingController();
    final bodyC = TextEditingController();

    String targetType = "department";
    String targetValue = teacherDept ?? "";

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "Create Announcement",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleC,
                decoration: const InputDecoration(
                  labelText: "Title",
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyC,
                decoration: const InputDecoration(
                  labelText: "Message",
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.black,
                value: targetType,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Send to",
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                items: [
                  DropdownMenuItem(
                    value: "department",
                    child: Text(
                      "Department (${teacherDept ?? 'N/A'})",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "class",
                    child: Text(
                      "Class (${teacherClass ?? 'N/A'})",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setDialogState(() {
                    targetType = v;
                    targetValue = v == "department"
                        ? teacherDept ?? ""
                        : teacherClass ?? "";
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleC.text.trim();
                final bodyText = bodyC.text.trim();

                if (title.isEmpty || bodyText.isEmpty) return;

                await _db.collection("announcements").add({
                  "title": title,
                  "body": bodyText,
                  "createdByUid": uid,
                  "createdByName": teacherName,
                  "createdAt": FieldValue.serverTimestamp(),
                  "target": {"type": targetType, "value": targetValue},
                });

                await _sendAnnouncementNotification(
                  title: title,
                  body: bodyText,
                  targetTopic: targetValue,
                );

                Get.back();
              },
              child: const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAnnouncement(String docId) async {
    await _db.collection("announcements").doc(docId).delete();
  }

  bool _filterAnnouncement(Map<String, dynamic> data) {
    final target = data["target"];
    if (target == null) return false;

    if (target["type"] == "all") return true;
    if (target["type"] == "department" && target["value"] == teacherDept) {
      return true;
    }
    if (target["type"] == "class" && target["value"] == teacherClass) {
      return true;
    }
    if (data["createdByUid"] == uid) return true;

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

          final docs = snapshot.data!.docs;
          final filtered = docs
              .where((e) => _filterAnnouncement(e.data()))
              .toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("No announcements"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final doc = filtered[i];
              final data = doc.data();
              final isOwner = data["createdByUid"] == uid;

              return Card(
                color: Colors.black,
                child: ListTile(
                  title: Text(
                    data["title"] ?? "",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["body"] ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (data["createdByName"] != null)
                        Text(
                          "By: ${data["createdByName"]}",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: isOwner
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Delete Announcement"),
                                content: const Text(
                                  "Are you sure you want to delete this announcement?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await _deleteAnnouncement(doc.id);
                                      Get.back();
                                    },
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAnnouncement,
        child: const Icon(Icons.add),
      ),
    );
  }
}
