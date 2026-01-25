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
        title: const Text("Group Info"),
        backgroundColor: const Color(0xFF1F2C34),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Assuming your 'classes' collection has lists of student/teacher IDs
        future: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;
          // Extract IDs from your class document
          List memberIds = [
            ...(data['teachers'] ?? []),
            ...(data['students'] ?? []),
          ];

          return ListView.builder(
            itemCount: memberIds.length,
            itemBuilder: (context, index) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberIds[index])
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  var userData = userSnap.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      userData['name'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      userData['role'] ?? 'Student',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: userData['role'] == 'teacher'
                        ? const Text(
                            "Admin",
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          )
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
