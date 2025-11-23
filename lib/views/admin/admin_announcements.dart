import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends State<AdminAnnouncementsScreen> {
  final _db = FirebaseFirestore.instance;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _openEditor({DocumentSnapshot? doc}) async {
    TextEditingController titleC =
        TextEditingController(text: doc?['title'] ?? '');
    TextEditingController bodyC =
        TextEditingController(text: doc?['body'] ?? '');

    String targetType = doc?['target']?['type'] ?? 'all';
    String targetValue = doc?['target']?['value'] ?? '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          doc == null ? "Create Announcement" : "Edit Announcement",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleC,
              decoration: const InputDecoration(labelText: "Title"),
              style: const TextStyle(color: Colors.white),
            ),
            TextField(
              controller: bodyC,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Message"),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: targetType,
              dropdownColor: Colors.black,
              items: const [
                DropdownMenuItem(value: "all", child: Text("All")),
                DropdownMenuItem(
                    value: "department", child: Text("Department")),
                DropdownMenuItem(value: "class", child: Text("Class")),
              ],
              onChanged: (v) => setState(() => targetType = v!),
            ),
            if (targetType != "all")
              TextField(
                onChanged: (v) => targetValue = v,
                controller: TextEditingController(text: targetValue),
                decoration: InputDecoration(
                  labelText: targetType == "department"
                      ? "Department"
                      : "Class (ex: CS1)",
                ),
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () async {
              if (titleC.text.trim().isEmpty ||
                  bodyC.text.trim().isEmpty) {
                Get.snackbar("Error", "Title & body required",
                    backgroundColor: Colors.red);
                return;
              }

              Map<String, dynamic> data = {
                "title": titleC.text.trim(),
                "body": bodyC.text.trim(),
                "createdByUid": uid,
                "createdAt": FieldValue.serverTimestamp(),
                "target": {
                  "type": targetType,
                  "value": targetType == "all" ? "" : targetValue.trim(),
                }
              };

              if (doc == null) {
                await _db.collection("announcements").add(data);
              } else {
                await _db.collection("announcements").doc(doc.id).update(data);
              }

              Get.back();
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    await _db.collection("announcements").doc(id).delete();
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
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              var a = docs[i].data() as Map<String, dynamic>;
              var target = a["target"] ?? {};

              return Card(
                child: ListTile(
                  title: Text(a["title"] ?? "",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    a["body"] ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: () => _openEditor(doc: docs[i]),
                          icon: const Icon(Icons.edit, color: Colors.white)),
                      IconButton(
                          onPressed: () => _delete(docs[i].id),
                          icon:
                              const Icon(Icons.delete, color: Colors.white)),
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
