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
        TextEditingController(text: doc?['title'] ?? '');
    TextEditingController bodyC =
        TextEditingController(text: doc?['body'] ?? '');

    String targetType = doc != null ? doc['target']['type'] : 'all';
    String targetValue = doc != null ? doc['target']['value'] : '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
            doc == null ? "Create Announcement" : "Edit Announcement",
            style: const TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: titleC,
            decoration: const InputDecoration(labelText: "Title"),
            style: const TextStyle(color: Colors.white),
          ),
          TextField(
            controller: bodyC,
            decoration: const InputDecoration(labelText: "Message"),
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            dropdownColor: Colors.black,
            value: targetType,
            items: const [
              DropdownMenuItem(value: "all", child: Text("All")),
              DropdownMenuItem(value: "department", child: Text("Department")),
              DropdownMenuItem(value: "class", child: Text("Class")),
            ],
            onChanged: (v) => targetType = v!,
          ),
          if (targetType != "all")
            TextField(
              decoration: const InputDecoration(labelText: "Value"),
              onChanged: (v) => targetValue = v,
              style: const TextStyle(color: Colors.white),
            ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel", style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () async {
              if (titleC.text.isEmpty || bodyC.text.isEmpty) {
                Get.snackbar("Error", "Fields cannot be empty",
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }

              Map<String, dynamic> payload = {
                "title": titleC.text.trim(),
                "body": bodyC.text.trim(),
                "createdByUid": uid,
                "createdAt": FieldValue.serverTimestamp(),
                "target": {
                  "type": targetType,
                  "value": targetValue,
                }
              };

              if (doc == null) {
                await _db.collection("announcements").add(payload);
              } else {
                await _db.collection("announcements").doc(doc.id).update(payload);
              }

              Get.back();
            },
            child: const Text("Save"),
          )
        ],
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              var d = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(d["title"], style: const TextStyle(color: Colors.white)),
                  subtitle: Text(d["body"], style: const TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _openEditor(doc: docs[i])),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _db.collection('announcements').doc(docs[i].id).delete(),
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
