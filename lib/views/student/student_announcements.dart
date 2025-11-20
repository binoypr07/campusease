import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  String? studentDept;
  String? studentClass;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStudentDetails();
  }

  Future<void> loadStudentDetails() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    var doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (doc.exists) {
      studentDept = doc["department"];
      studentClass = doc["classYear"];
    }

    setState(() {
      loading = false;
    });
  }

  bool canSeeAnnouncement(Map<String, dynamic> data) {
    String target = data["target"];
    String value = data["targetValue"] ?? "";

    if (target == "all") return true;
    if (target == "department" && value == studentDept) return true;
    if (target == "class" && value == studentClass) return true;

    return false;
  }

  Widget buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return  Scaffold(
        appBar: AppBar(title: Text("Announcements")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("announcements")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          var docs = snapshot.data!.docs;

          // filter announcements student is allowed to see
          var filtered = docs.where((doc) {
            return canSeeAnnouncement(doc.data());
          }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text(
                "No announcements available",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              var ann = filtered[index].data();
              String title = ann["title"];
              String msg = ann["message"];
              Timestamp ts = ann["createdAt"];
              String sender = ann["createdBy"];
              String target = ann["target"];
              String value = ann["targetValue"] ?? "";

              String time = DateFormat("d MMM, h:mm a")
                  .format(ts.toDate());

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.white, width: 1.3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // MESSAGE
                      Text(
                        msg,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          // TAG
                          if (target == "all") buildTag("Global"),
                          if (target == "department") buildTag("Department: $value"),
                          if (target == "class") buildTag("Class: $value"),

                          const Spacer(),

                          Text(
                            time,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "By: $sender",
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
