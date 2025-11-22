// lib/views/announcements/teacher_announcements.dart
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

class _TeacherAnnouncementsScreenState extends State<TeacherAnnouncementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? teacherDept;
  String? assignedClass;
  String uid = FirebaseAuth.instance.currentUser!.uid;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  Future<void> _loadTeacher() async {
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        teacherDept = (doc.data() ?? {})['department'] as String? ?? '';
        assignedClass = (doc.data() ?? {})['assignedClass'] as String? ?? '';
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  // teacher can create announcement only for department or assigned class (or all if allowed)
  Future<void> _openCreate() async {
    TextEditingController titleC = TextEditingController();
    TextEditingController bodyC = TextEditingController();
    String targetType = 'department'; // default for teacher
    String targetValue = teacherDept ?? '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Create Announcement", style: TextStyle(color: Colors.white)),
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
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'department', child: Text('Department (${teacherDept ?? "N/A"})')),
                  DropdownMenuItem(value: 'class', child: Text('Class (${assignedClass ?? "N/A"})')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    targetType = v;
                    targetValue = (v == 'department') ? (teacherDept ?? '') : (assignedClass ?? '');
                  });
                },
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
                    backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
                return;
              }

              // Build payload
              Map<String, dynamic> payload = {
                'title': title,
                'body': body,
                'createdByUid': uid,
                'createdAt': FieldValue.serverTimestamp(),
                'target': {
                  'type': targetType,
                  'value': targetValue,
                }
              };

              try {
                var ref = await _db.collection('announcements').add(payload);

                // Add to pushQueue for server/cloud function processing
                await _db.collection('pushQueue').add({
                  'announcementId': ref.id,
                  'target': payload['target'],
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Get.back();
                Get.snackbar("Created", "Announcement created",
                    backgroundColor: Colors.black, colorText: Colors.white);
              } catch (e) {
                Get.snackbar("Error", "Failed: $e",
                    backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  // filter client-side for teacher relevant announcements
  bool _isRelevant(Map<String, dynamic> docData) {
    var t = docData['target'] as Map<String, dynamic>? ?? {'type': 'all', 'value': ''};
    String type = t['type'] ?? 'all';
    String value = (t['value'] ?? '').toString();

    if (type == 'all') return true;
    if (type == 'department' && teacherDept != null && value == teacherDept) return true;
    if (type == 'class' && assignedClass != null && value == assignedClass) return true;

    // also show announcements created by this teacher
    if ((docData['createdByUid'] ?? '') == uid) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
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
          var filtered = docs.where((d) => _isRelevant(d.data() as Map<String, dynamic>)).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("No announcements", style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              var d = filtered[idx];
              var m = d.data() as Map<String, dynamic>;
              var title = m['title'] ?? '';
              var body = m['body'] ?? '';
              var target = (m['target'] ?? {}) as Map<String, dynamic>;
              String targetText = target['type'] == 'all'
                  ? 'All'
                  : '${target['type']}:${target['value']}';
              bool mine = (m['createdByUid'] ?? '') == uid;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(body, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text("Target: $targetText", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: mine ? const Icon(Icons.person, color: Colors.white) : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}
