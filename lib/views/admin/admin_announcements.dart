import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String? adminName;

  final List<String> departments = [
    "Computer Science",
    "Physics",
    "Chemistry",
    "Maths",
    "Malayalam",
    "Hindi",
    "English",
    "History",
    "Economics",
    "Commerce",
    "Zoology",
    "Botany",
  ];

  final Map<String, List<String>> departmentClasses = {
    "Computer Science": ["CS1", "CS2", "CS3", "CS4"],
    "Physics": ["PHY1", "PHY2", "PHY3", "PHY4"],
    "Chemistry": ["CHE1", "CHE2", "CHE3", "CHE4"],
    "Maths": ["MAT1", "MAT2", "MAT3", "MAT4"],
    "Commerce": ["BCOM1", "BCOM2", "BCOM3", "BCOM4"],
    "Economics": ["ECO1", "ECO2", "ECO3", "ECO4"],
    "Hindi": ["HIN1", "HIN2", "HIN3", "HIN4"],
    "History": ["HIS1", "HIS2", "HIS3", "HIS4"],
    "English": ["ENG1", "ENG2", "ENG3", "ENG4"],
    "Malayalam": ["MAL1", "MAL2", "MAL3", "MAL4"],
    "Zoology": ["ZOO1", "ZOO2", "ZOO3", "ZOO4"],
    "Botany": ["BOO1", "BOO2", "BOO3", "BOO4"],
  };

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final doc = await _db.collection("users").doc(uid).get();
    adminName = doc.data()?["name"] ?? "Admin";
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RENDER WAKEUP  — calls /users only to keep the server alive
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _wakeUpRenderServer(String targetTopic) async {
    final url = Uri.parse('https://shade-0pxb.onrender.com/users');
    try {
      await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "sender": "System_Wakeup",
              "text": "Admin_Announcement_Entry",
              "classId": targetTopic.isEmpty ? "all" : targetTopic,
              "time": DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print("Render wakeup: Server waking up or offline. (Ignoring)");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REAL FCM NOTIFICATION — mirrors _sendWhatsAppStyleNotification exactly.
  // For "all" target, sends to the "all" topic so every student receives it.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _sendAnnouncementNotification({
    required String title,
    required String body,
    required String targetType,
    required String targetValue,
  }) async {
    // Determine the FCM topic:
    //   "all"        → topic = "all"
    //   "department" → topic = "Computer_Science" (spaces → underscores)
    //   "class"      → topic = "CS1"
    final String rawTopic = targetType == "all"
        ? "all"
        : targetValue.replaceAll(' ', '_');

    final url = Uri.parse('https://shade-0pxb.onrender.com/notification');
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "from": "CampusEase",
          "to": "/topics/$rawTopic", // ← same format as GlobalChatScreen
          "title": "📢 $title",
          "body": "${adminName ?? 'Admin'}: $body",
          "data": {
            "type": "announcement",
            "targetType": targetType,
            "targetValue": targetValue,
            "senderId": uid,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          },
        }),
      );
      print("Admin announcement notification sent to topic: $rawTopic");
    } catch (e) {
      print("Failed to send admin announcement notification: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE / EDIT DIALOG
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _openEditor({DocumentSnapshot? doc}) async {
    final titleC = TextEditingController(text: doc?['title'] ?? '');
    final bodyC = TextEditingController(text: doc?['body'] ?? '');

    String targetType = doc != null ? doc['target']['type'] : 'all';
    String targetValue = doc != null ? doc['target']['value'] : '';
    String? selectedDeptForClass;

    // Wake up Render early so it is ready when the user hits Save
    _wakeUpRenderServer(targetValue);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          title: Text(
            doc == null ? "Create Announcement" : "Edit Announcement",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: bodyC,
                  decoration: const InputDecoration(
                    labelText: "Message",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Select Target",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                ),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.black,
                  value: targetType,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: "all", child: Text("All")),
                    DropdownMenuItem(
                      value: "department",
                      child: Text("Department"),
                    ),
                    DropdownMenuItem(value: "class", child: Text("Class")),
                  ],
                  onChanged: (v) {
                    setDialogState(() {
                      targetType = v!;
                      targetValue = '';
                      selectedDeptForClass = null;
                    });
                  },
                ),

                if (targetType == "department") ...[
                  const SizedBox(height: 25),
                  const Text(
                    "Select Department",
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    value: targetValue.isEmpty ? null : targetValue,
                    style: const TextStyle(color: Colors.white),
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => targetValue = v!),
                  ),
                ],

                if (targetType == "class") ...[
                  const SizedBox(height: 25),
                  const Text(
                    "1. Select Department",
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    value: selectedDeptForClass,
                    style: const TextStyle(color: Colors.white),
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedDeptForClass = v;
                        targetValue = '';
                      });
                    },
                  ),
                  if (selectedDeptForClass != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "2. Select Class",
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.black,
                      value: targetValue.isEmpty ? null : targetValue,
                      style: const TextStyle(color: Colors.white),
                      items: departmentClasses[selectedDeptForClass]!
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => targetValue = v!),
                    ),
                  ],
                ],
              ],
            ),
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

                final payload = {
                  "title": title,
                  "body": bodyText,
                  "createdByUid": uid,
                  "createdByName": adminName,
                  "createdAt": FieldValue.serverTimestamp(),
                  "target": {"type": targetType, "value": targetValue},
                };

                // 1. Save / update Firestore
                if (doc == null) {
                  await _db.collection("announcements").add(payload);
                } else {
                  await _db
                      .collection("announcements")
                      .doc(doc.id)
                      .update(payload);
                }

                // 2. Send real FCM push notification via /notification endpoint
                await _sendAnnouncementNotification(
                  title: title,
                  body: bodyText,
                  targetType: targetType,
                  targetValue: targetValue,
                );

                Get.back();
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection("announcements")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              return Card(
                color: Colors.grey[900],
                child: ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.blueAccent),
                  title: Text(
                    d["title"] ?? "",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d["body"] ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Target: ${d["target"]?["type"] == "all" ? "All" : d["target"]?["value"] ?? ""}",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _openEditor(doc: docs[i]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => showDialog(
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
                                  await _db
                                      .collection('announcements')
                                      .doc(docs[i].id)
                                      .delete();
                                  Get.back();
                                },
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
