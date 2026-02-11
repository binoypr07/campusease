import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    setState(() => loading = false);
  }

  // ---------------- SYNC TO RENDER (FOR POPUP) ----------------
  Future<void> syncAnnouncement(
    String title,
    String body,
    String targetTopic,
  ) async {
    final url = Uri.parse('https://shade-0pxb.onrender.com/users');
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender": "Announcement",
          "text": "$title: $body",
          "classId":
              targetTopic, 
        }),
      );
      print("Announcement notification triggered successfully");
    } catch (e) {
      print("Error syncing announcement: $e");
    }
  }

  // ---------------- CREATE ANNOUNCEMENT ----------------
  Future<void> _createAnnouncement() async {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();

    String targetType = "department";
    String targetValue = teacherDept ?? "";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
              decoration: const InputDecoration(labelText: "Title"),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bodyC,
              decoration: const InputDecoration(labelText: "Message"),
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: targetType,
              items: [
                DropdownMenuItem(
                  value: "department",
                  child: Text("Department ($teacherDept)"),
                ),
                DropdownMenuItem(
                  value: "class",
                  child: Text("Class ($teacherClass)"),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                targetType = v;
                targetValue = v == "department"
                    ? teacherDept ?? ""
                    : teacherClass ?? "";
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleC.text.trim();
              final bodyText = bodyC.text.trim();

              // 1. Save to Firebase
              await _db.collection("announcements").add({
                "title": title,
                "body": bodyText,
                "createdByUid": uid,
                "createdAt": FieldValue.serverTimestamp(),
                "target": {"type": targetType, "value": targetValue},
              });

              // 2. Trigger Notification Popup via Render
              syncAnnouncement(title, bodyText, targetValue);

              Get.back();
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  // ---------------- DELETE ANNOUNCEMENT ----------------
  Future<void> _deleteAnnouncement(String docId) async {
    await _db.collection("announcements").doc(docId).delete();
  }

  // ---------------- FILTER LOGIC ----------------
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
                  subtitle: Text(
                    data["body"] ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),
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
                                    child: const Text("Delete"),
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
