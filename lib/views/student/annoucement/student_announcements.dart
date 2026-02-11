import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    load();
  }

  Future<void> load() async {
    var doc = await _db.collection("users").doc(uid).get();
    classYear = doc["classYear"];
    department = doc["department"];
    setState(() => loading = false);
  }

  bool _filter(Map<String, dynamic> d) {
    var t = d["target"];

    if (t["type"] == "all") return true;
    if (t["type"] == "department" && t["value"] == department) return true;
    if (t["type"] == "class" && t["value"] == classYear) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
      body: StreamBuilder(
        stream: _db
            .collection("announcements")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var filtered = snapshot.data!.docs
              .where((e) => _filter(e.data()))
              .toList();

          return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                var d = filtered[i].data();

                return Card(
                  child: ListTile(
                    title:
                        Text(d["title"], style: const TextStyle(color: Colors.white)),
                    subtitle:
                        Text(d["body"], style: const TextStyle(color: Colors.white70)),
                  ),
                );
              });
        },
      ),
    );
  }
}
