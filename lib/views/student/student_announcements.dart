import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String? classYear;
  String? department;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStudentInfo();
  }

  Future<void> loadStudentInfo() async {
    var doc = await _db.collection("users").doc(uid).get();
    if (doc.exists) {
      var data = doc.data()!;
      classYear = data["classYear"];
      department = data["department"];
    }
    setState(() => loading = false);
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
      body: StreamBuilder(
        stream: _db
            .collection("announcements")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          var allDocs = snapshot.data!.docs;

          // -------------------------
          // FILTER LOGIC FOR STUDENTS
          // -------------------------
          var filtered = allDocs.where((doc) {
            var a = doc.data();
            String audience = a["audienceType"] ?? "all";

            return audience == "all" ||
                audience == "students" ||
                audience == classYear ||
                audience == department;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text(
                "No announcements for you",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              var a = filtered[index].data();

              return Card(
                color: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                      const BorderSide(color: Colors.white70, width: 1.2),
                ),
                child: ListTile(
                  title: Text(
                    a["title"] ?? "",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    a["message"] ?? "",
                    style: const TextStyle(color: Colors.white70),
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
