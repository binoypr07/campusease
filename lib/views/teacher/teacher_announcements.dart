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
    var doc = await _db.collection("users").doc(uid).get();
    if (doc.exists) {
      var data = doc.data()!;
      teacherDept = data["department"];
      assignedClass = data["assignedClass"];
    }
    setState(() => loading = false);
  }

  // --------------------------
  // CREATE ANNOUNCEMENT
  // --------------------------
  Future<void> _openCreate() async {
    TextEditingController titleC = TextEditingController();
    TextEditingController msgC = TextEditingController();

    String audienceType = "department"; // default
    String audienceValue = teacherDept ?? "";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Create Announcement",
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: "Title"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: msgC,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Message"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),

              // TARGET SELECTOR
              DropdownButtonFormField(
                value: audienceType,
                dropdownColor: Colors.black,
                decoration: const InputDecoration(labelText: "Target"),
                items: [
                  DropdownMenuItem(
                      value: "department",
                      child: Text("Department ($teacherDept)")),
                  DropdownMenuItem(
                      value: "class",
                      child: Text("Class ($assignedClass)")),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    audienceType = v;
                    audienceValue =
                        v == "department" ? teacherDept! : assignedClass!;
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
              String msg = msgC.text.trim();

              if (title.isEmpty || msg.isEmpty) {
                Get.snackbar("Error", "All fields required",
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }

              Map<String, dynamic> data = {
                "title": title,
                "message": msg,
                "createdByUid": uid,
                "createdAt": FieldValue.serverTimestamp(),
                "audienceType": audienceType,
                "audienceValue": audienceValue,
              };

              await _db.collection("announcements").add(data);

              Get.back();
              Get.snackbar("Success", "Announcement Sent",
                  backgroundColor: Colors.black, colorText: Colors.white);
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  // FILTER ANNOUNCEMENTS FOR TEACHER
  bool isVisibleToTeacher(Map<String, dynamic> a) {
    String type = a["audienceType"] ?? "all";
    String value = a["audienceValue"] ?? "";

    if (type == "all") return true;
    if (type == "department" && value == teacherDept) return true;
    if (type == "class" && value == assignedClass) return true;

    if ((a["createdByUid"] ?? "") == uid) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Announcements")),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: _db
            .collection("announcements")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          var docs = snap.data!.docs;
          var filtered = docs
              .map((d) => d.data() as Map<String, dynamic>)
              .where((a) => isVisibleToTeacher(a))
              .toList();

          if (filtered.isEmpty) {
            return const Center(
                child: Text("No announcements",
                    style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              var a = filtered[i];

              return Card(
                color: Colors.black,
                shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.white70)),
                child: ListTile(
                  title: Text(a["title"],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(a["message"] ?? "",
                      style: const TextStyle(color: Colors.white70)),
                  trailing: (a["createdByUid"] == uid)
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
