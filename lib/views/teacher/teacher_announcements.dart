import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class TeacherAnnouncementScreen extends StatefulWidget {
  const TeacherAnnouncementScreen({super.key});

  @override
  State<TeacherAnnouncementScreen> createState() =>
      _TeacherAnnouncementScreenState();
}

class _TeacherAnnouncementScreenState
    extends State<TeacherAnnouncementScreen> {
  TextEditingController titleC = TextEditingController();
  TextEditingController messageC = TextEditingController();

  String? department;
  String? assignedClass;

  @override
  void initState() {
    super.initState();
    loadTeacher();
  }

  Future<void> loadTeacher() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    setState(() {
      department = doc["department"];
      assignedClass = doc["assignedClass"];
    });
  }

  Future<void> _createAnnouncement() async {
    if (titleC.text.isEmpty || messageC.text.isEmpty) {
      Get.snackbar("Error", "Fill all details",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    await FirebaseFirestore.instance.collection("announcements").add({
      "title": titleC.text,
      "message": messageC.text,
      "roleTarget": "teacherArea",
      "departmentTarget": department,
      "classTarget": assignedClass ?? "",
      "timestamp": Timestamp.now(),
      "creatorRole": "teacher",
    });

    titleC.clear();
    messageC.clear();

    Get.snackbar("Success", "Announcement sent!",
        backgroundColor: Colors.green, colorText: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    if (department == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Announcements")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black,
            builder: (_) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleC,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageC,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Message"),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                        onPressed: _createAnnouncement,
                        child: const Text("Send"))
                  ],
                ),
              );
            },
          );
        },
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("announcements")
            .where("creatorRole", isEqualTo: "teacher")
            .where("departmentTarget", isEqualTo: department)
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
              child: Text(
                "No Announcements Yet",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              var a = docs[i];

              return Card(
                child: ListTile(
                  title: Text(a["title"],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  subtitle: Text(a["message"],
                      style: const TextStyle(color: Colors.white70)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
