import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  TextEditingController title = TextEditingController();
  TextEditingController message = TextEditingController();

  String target = "All Students";

  final List<String> targetOptions = [
    "All Students",
    "All Teachers",
    "All Users",
    "By Department"
  ];

  String? selectedDept;

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
    "Botany"
  ];

  bool loading = false;

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
      "sender": "admin",
      "target": target,
      "department": selectedDept ?? "",
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
    selectedDept = null;
  }

  void editAnnouncement(DocumentSnapshot doc) {
    title.text = doc["title"];
    message.text = doc["message"];
    target = doc["target"];
    selectedDept = doc["department"] == "" ? null : doc["department"];

    sendAnnouncement(docId: doc.id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection("announcements").doc(id).delete();
    Get.snackbar("Deleted", "Announcement Removed!",
        backgroundColor: Colors.black, colorText: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Announcements")),
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

            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: target,
              dropdownColor: Colors.black,
              decoration: const InputDecoration(labelText: "Send To"),
              items: targetOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => target = v!),
            ),

            if (target == "By Department")
              DropdownButtonFormField<String>(
                initialValue: selectedDept,
                dropdownColor: Colors.black,
                decoration: const InputDecoration(labelText: "Department"),
                items: departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => selectedDept = v),
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

            const Text("Previous Announcements",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder(
                stream: _db
                    .collection("announcements")
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
                                  onPressed: () => editAnnouncement(doc)),
                              IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      deleteAnnouncement(doc.id)),
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
