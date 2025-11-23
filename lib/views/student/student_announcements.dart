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

  bool _isRelevant(Map<String, dynamic> a) {
    var t = (a["target"] ?? {}) as Map<String, dynamic>;
    String type = t["type"] ?? "all";
    String value = t["value"] ?? "";

    if (type == "all") return true;
    if (type == "department" && value == department) return true;
    if (type == "class" && value == classYear) return true;

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

          var docs = snapshot.data!.docs;
          var filtered = docs
              .where((d) => _isRelevant(d.data() as Map<String, dynamic>))
              .toList();

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
              var a = filtered[index].data() as Map<String, dynamic>;

              return Card(
                color: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white70, width: 1.2),
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
                    a["body"] ?? "",
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
