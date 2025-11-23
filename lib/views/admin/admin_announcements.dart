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

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _openEditor({DocumentSnapshot? doc}) async {
    TextEditingController titleC =
        TextEditingController(text: doc != null ? doc['title'] : '');
    TextEditingController bodyC =
        TextEditingController(text: doc != null ? doc['body'] : '');

    String targetType = doc != null ? doc['target']['type'] : 'all';
    String targetValue = doc != null ? doc['target']['value'] : '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          doc == null ? "Create Announcement" : "Edit Announcement",
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleC,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyC,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Message"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: targetType,
                dropdownColor: Colors.black,
                decoration: const InputDecoration(labelText: "Target"),
                items: const [
                  DropdownMenuItem(value: "all", child: Text("All")),
                  DropdownMenuItem(value: "department", child: Text("Department")),
                  DropdownMenuItem(value: "class", child: Text("Class")),
                ],
                onChanged: (v) => setState(() => targetType = v!),
              ),
              const SizedBox(height: 8),
              if (targetType != "all")
                TextField(
                  controller: TextEditingController(text: targetValue),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText:
                        targetType == "department" ? "Department" : "Class",
                  ),
                  onChanged: (v) => targetValue = v,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleC.text.trim().isEmpty ||
                  bodyC.text.trim().isEmpty) {
                Get.snackbar(
                  "Error",
                  "Title & Message required",
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
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

              try {
                if (doc == null) {
                  await _db.collection("announcements").add(data);
                } else {
                  await _db
                      .collection("announcements")
                      .doc(doc.id)
                      .update(data);
                }

                Get.back();
                Get.snackbar(
                  "Success",
                  "Announcement Saved",
                  backgroundColor: Colors.black,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  "Error",
                  "Failed: $e",
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    await _db.collection("announcements").doc(id).delete();
    Get.snackbar("Deleted", "Announcement removed",
        backgroundColor: Colors.black, colorText: Colors.white);
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
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
                child: Text("No Announcements",
                    style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              var d = docs[i];
              var a = d.data() as Map<String, dynamic>;

              String targetText = a["target"]["type"] == "all"
                  ? "All Users"
                  : "${a['target']['type']} : ${a['target']['value']}";

              return Card(
                child: ListTile(
                  title: Text(a["title"],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(a["body"],
                      style: const TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _openEditor(doc: d)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _delete(d.id)),
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
