import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  TextEditingController title = TextEditingController();
  TextEditingController message = TextEditingController();

  String? teacherDept;
  String? assignedClass;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadTeacherInfo();
  }

  Future<void> loadTeacherInfo() async {
    var doc = await _db.collection("users").doc(uid).get();
    teacherDept = doc["department"];
    assignedClass = doc["assignedClass"];
    setState(() {});
  }

  Future<void> sendAnnouncement({String? docId}) async {
    if (title.text.trim().isEmpty || message.text.trim().isEmpty) {
      Get.snackbar("Missing Fields", "Please fill all fields",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => loading = true);

    Map<String, dynamic> data = {
      "title": title.text.trim(),
      "message": message.text.trim(),
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "sender": uid,
      "senderType": "teacher",
      "department": teacherDept,
      "class": assignedClass,
    };

    if (docId == null) {
      await _db.collection("announcements").add(data);
      Get.snackbar("Success", "Announcement Sent!",
          backgroundColor: Colors.black, colorText: Colors.white);
    } else {
      await _db.collection("announcements").doc(docId).update(data);
      Get.snackbar("Updated", "Announcement Updated!",
          backgroundColor: Colors.black, colorText: Colors.white);
    }

    setState(() => loading = false);
    title.clear();
    message.clear();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection("announcements").doc(id).delete();
    Get.snackbar("Deleted", "Announcement Removed!",
        backgroundColor: Colors.black, colorText: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    if (teacherDept == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Announcements")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: message,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Message"),
            ),

            const SizedBox(height: 14),

            ElevatedButton(
              onPressed: loading ? null : () => sendAnnouncement(),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("Send Announcement"),
            ),

            const SizedBox(height: 20),

            const Divider(color: Colors.white),

            const Text("My Previous Announcements",
                style: TextStyle(fontSize: 18, color: Colors.white)),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder(
                stream: _db
                    .collection("announcements")
                    .where("sender", isEqualTo: uid)
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }

                  var docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text("No announcements yet",
                            style: TextStyle(color: Colors.white70)));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      return Card(
                        child: ListTile(
                          title: Text(doc["title"],
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(doc["message"],
                              style: const TextStyle(color: Colors.white70)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white),
                                onPressed: () =>
                                    sendAnnouncement(docId: doc.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () =>
                                    deleteAnnouncement(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
