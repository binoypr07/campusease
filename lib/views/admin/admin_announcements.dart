// lib/views/announcements/admin_announcements.dart
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
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // show create/edit dialog
  Future<void> _openEditor({DocumentSnapshot? doc}) async {
    TextEditingController titleC =
        TextEditingController(text: doc != null ? doc['title'] ?? '' : '');
    TextEditingController bodyC =
        TextEditingController(text: doc != null ? doc['body'] ?? '' : '');
    String targetType = doc != null
        ? (doc['target']?['type'] ?? 'all')
        : 'all'; // 'all' | 'department' | 'class'
    String targetValue = doc != null ? (doc['target']?['value'] ?? '') : '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(doc == null ? "Create Announcement" : "Edit Announcement",
            style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: "Title"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyC,
                maxLines: 5,
                decoration: const InputDecoration(labelText: "Message"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: targetType,
                dropdownColor: Colors.black,
                decoration: const InputDecoration(labelText: "Target"),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'department', child: Text('Department')),
                  DropdownMenuItem(value: 'class', child: Text('Class')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    targetType = v;
                  });
                },
              ),
              const SizedBox(height: 8),
              if (targetType != 'all')
                TextField(
                  onChanged: (v) => targetValue = v,
                  controller: TextEditingController(text: targetValue),
                  decoration: InputDecoration(
                    labelText:
                        targetType == 'department' ? "Department name" : "Class (eg: CS1)",
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              String title = titleC.text.trim();
              String body = bodyC.text.trim();

              if (title.isEmpty || body.isEmpty) {
                Get.snackbar("Error", "Title and message required",
                    backgroundColor: Colors.red.withOpacity(0.7),
                    colorText: Colors.white);
                return;
              }

              Map<String, dynamic> payload = {
                'title': title,
                'body': body,
                'createdByUid': uid,
                'createdAt': FieldValue.serverTimestamp(),
                'target': {
                  'type': targetType,
                  'value': targetType == 'all' ? '' : (targetValue.trim())
                }
              };

              try {
                if (doc == null) {
                  var ref = await _db.collection('announcements').add(payload);

                  // Add a pushQueue doc so a Cloud Function (or server) can send FCM.
                  await _db.collection('pushQueue').add({
                    'announcementId': ref.id,
                    'target': payload['target'],
                    'createdAt': FieldValue.serverTimestamp(),
                    // optional: add 'sent': false field for function to update
                  });
                } else {
                  await _db.collection('announcements').doc(doc.id).update({
                    'title': title,
                    'body': body,
                    'target': payload['target'],
                    'editedAt': FieldValue.serverTimestamp(),
                  });

                  await _db.collection('pushQueue').add({
                    'announcementId': doc.id,
                    'target': payload['target'],
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }

                Get.back();
                Get.snackbar("Success", "Announcement saved",
                    backgroundColor: Colors.black, colorText: Colors.white);
              } catch (e) {
                Get.snackbar("Error", "Failed: $e",
                    backgroundColor: Colors.red.withOpacity(0.7),
                    colorText: Colors.white);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(String id) async {
    try {
      await _db.collection('announcements').doc(id).delete();
      Get.snackbar("Deleted", "Announcement removed",
          backgroundColor: Colors.black, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Delete failed: $e",
          backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}", style: const TextStyle(color: Colors.white)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No announcements yet", style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              var d = docs[idx];
              var t = d['title'] ?? '';
              var b = d['body'] ?? '';
              var target = (d['target'] ?? {}) as Map<String, dynamic>;
              String targetText = target['type'] == 'all'
                  ? 'All'
                  : '${target['type']}:${target['value']}';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(b, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text("Target: $targetText", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _openEditor(doc: d),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deleteAnnouncement(d.id),
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
