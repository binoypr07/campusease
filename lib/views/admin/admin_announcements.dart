import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // --- DATA LISTS ---
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
          "sender": "Admin Announcement",
          "text": "$title: $body",
          "classId": targetTopic.isEmpty ? "all" : targetTopic,
        }),
      );
      print("Admin Notification triggered successfully");
    } catch (e) {
      print("Error syncing admin announcement: $e");
    }
  }

  Future<void> _openEditor({DocumentSnapshot? doc}) async {
    TextEditingController titleC = TextEditingController(
      text: doc?['title'] ?? '',
    );
    TextEditingController bodyC = TextEditingController(
      text: doc?['body'] ?? '',
    );

    String targetType = doc != null ? doc['target']['type'] : 'all';
    String targetValue = doc != null ? doc['target']['value'] : '';

    // For nested Class selection logic
    String? selectedDeptForClass;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                    setState(() {
                      targetType = v!;
                      targetValue = '';
                    });
                  },
                ),

                // --- DYNAMIC SELECTION BASED ON TARGET TYPE ---
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
                    onChanged: (v) => setState(() => targetValue = v!),
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
                      setState(() {
                        selectedDeptForClass = v;
                        targetValue = ''; // Reset class when dept changes
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
                      onChanged: (v) => setState(() => targetValue = v!),
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
                if (titleC.text.isEmpty || bodyC.text.isEmpty) return;

                final payload = {
                  "title": titleC.text.trim(),
                  "body": bodyC.text.trim(),
                  "createdByUid": uid,
                  "createdAt": FieldValue.serverTimestamp(),
                  "target": {"type": targetType, "value": targetValue},
                };

                if (doc == null) {
                  await _db.collection("announcements").add(payload);
                } else {
                  await _db
                      .collection("announcements")
                      .doc(doc.id)
                      .update(payload);
                }

                syncAnnouncement(
                  titleC.text,
                  bodyC.text,
                  targetType == "all" ? "all" : targetValue,
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
      body: StreamBuilder(
        stream: _db
            .collection("announcements")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              var d = docs[i].data() as Map<String, dynamic>;
              return Card(
                color: Colors.grey[900],
                child: ListTile(
                  title: Text(
                    d["title"] ?? "",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    d["body"] ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _openEditor(doc: docs[i]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _db
                            .collection('announcements')
                            .doc(docs[i].id)
                            .delete(),
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
        child: const Icon(Icons.add),
        onPressed: () => _openEditor(),
      ),
    );
  }
}
