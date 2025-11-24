import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    load();
  }

  Future<void> load() async {
    var doc = await _db.collection("users").doc(uid).get();
    teacherDept = doc["department"];
    teacherClass = doc["assignedClass"];
    setState(() => loading = false);
  }

  Future<void> _create() async {
    TextEditingController titleC = TextEditingController();
    TextEditingController bodyC = TextEditingController();

    String targetType = "department";
    String targetValue = teacherDept ?? "";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Create Announcement",
            style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: titleC,
              decoration: const InputDecoration(labelText: "Title"),
              style: const TextStyle(color: Colors.white)),
          TextField(
              controller: bodyC,
              decoration: const InputDecoration(labelText: "Message"),
              maxLines: 4,
              style: const TextStyle(color: Colors.white)),
          DropdownButtonFormField(
            dropdownColor: Colors.black,
            initialValue: targetType,
            items: [
              DropdownMenuItem(
                  value: "department",
                  child: Text("Department ($teacherDept)")),
              DropdownMenuItem(
                  value: "class", child: Text("Class ($teacherClass)")),
            ],
            onChanged: (v) {
              targetType = v!;
              targetValue =
                  v == "department" ? teacherDept! : teacherClass ?? "";
            },
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel", style: TextStyle(color: Colors.white))),
          ElevatedButton(
              onPressed: () async {
                await _db.collection("announcements").add({
                  "title": titleC.text.trim(),
                  "body": bodyC.text.trim(),
                  "createdByUid": uid,
                  "createdAt": FieldValue.serverTimestamp(),
                  "target": {"type": targetType, "value": targetValue},
                });
                Get.back();
              },
              child: const Text("Send"))
        ],
      ),
    );
  }

  bool _filter(Map<String, dynamic> doc) {
    var t = doc["target"];
    if (t["type"] == "all") return true;
    if (t["type"] == "department" && t["value"] == teacherDept) return true;
    if (t["type"] == "class" && t["value"] == teacherClass) return true;
    if (doc["createdByUid"] == uid) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

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

          return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                var d = filtered[i].data();

                return Card(
                  child: ListTile(
                    title: Text(d["title"],
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(d["body"],
                        style: const TextStyle(color: Colors.white70)),
                  ),
                );
              });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
    );
  }
}
