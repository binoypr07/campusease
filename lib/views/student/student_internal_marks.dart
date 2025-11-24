import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentInternalMarks extends StatelessWidget {
  final String className;
  const StudentInternalMarks({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Internal Marks")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("internal_marks")
            .doc("${className}_marks")
            .collection("students")
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null || data.isEmpty) {
            return const Center(child: Text("No marks found"));
          }

          // Convert map entries into a list
          final subjects = data.entries.map((e) {
            return {"name": e.key, "mark": e.value};
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                child: ListTile(
                  title: Text(subject["name"]),
                  trailing: Text(subject["mark"].toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
