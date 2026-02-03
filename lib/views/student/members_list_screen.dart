import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MembersListScreen extends StatelessWidget {
  final String classId;
  const MembersListScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Members: $classId"),
        backgroundColor: const Color(0xFF1F2C34),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // We query the whole 'users' collection
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) return const SizedBox();

          // FILTER LOCALLY: This solves the "Different Field Name" problem
          var allDocs = snapshot.data!.docs;
          var members = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            // Match if it's a student's classYear OR a teacher's assignedClass
            return data['classYear'] == classId ||
                data['assignedClass'] == classId;
          }).toList();

          if (members.isEmpty) {
            return const Center(
              child: Text(
                "No members found",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // SORT: Teacher at the top
          members.sort((a, b) {
            var aRole = (a.data() as Map<String, dynamic>)['role'] ?? '';
            var bRole = (b.data() as Map<String, dynamic>)['role'] ?? '';
            if (aRole == 'teacher' && bRole != 'teacher') return -1;
            if (aRole != 'teacher' && bRole == 'teacher') return 1;
            return 0;
          });

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              var userData = members[index].data() as Map<String, dynamic>;
              bool isTeacher = userData['role'] == 'teacher';

              return Card(
                color: const Color(0xFF1F2C34),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isTeacher
                        ? Colors.green
                        : Colors.blueAccent,
                    child: Icon(
                      isTeacher ? Icons.verified_user : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    userData['name'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    isTeacher
                        ? "Teacher (${userData['subjects']?.join(', ')})"
                        : "Student",
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: isTeacher
                      ? const Text(
                          "ADMIN",
                          style: TextStyle(color: Colors.green),
                        )
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
