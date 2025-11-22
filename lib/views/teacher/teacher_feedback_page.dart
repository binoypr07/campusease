import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherFeedbackPage extends StatelessWidget {
  final String className;

  const TeacherFeedbackPage({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    print("DEBUG: TeacherFeedbackPage opened for class → $className");

    return Scaffold(
      appBar: AppBar(title: const Text("Student Feedback")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks') // top-level collection
            .where('classYear', isEqualTo: className)
            .snapshots(), // removed orderBy to avoid errors
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No feedback received"));
          }

          final feedbacks = snapshot.data!.docs;

          print("DEBUG: Feedback documents received → ${feedbacks.length}");
          for (var doc in feedbacks) {
            print("DEBUG: Feedback doc → ${doc.data()}");
          }

          // Manual sorting by timestamp (descending)
          feedbacks.sort((a, b) {
            final aTime = (a['timestamp'] as Timestamp?)?.toDate();
            final bTime = (b['timestamp'] as Timestamp?)?.toDate();
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final data = feedbacks[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['studentName'] ?? "Unknown Student"),
                  subtitle: Text(data['feedback'] ?? ""),
                  trailing: Text(
                    data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp)
                              .toDate()
                              .toString()
                              .split('.')[0]
                        : "No timestamp",
                    style: const TextStyle(fontSize: 10),
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
