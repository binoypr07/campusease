import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class StudentInfoPage extends StatelessWidget {
  const StudentInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String studentId = Get.arguments ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text("Student Info")),
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection("students")
            .doc(studentId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("No student found"));
          }

          var data = snapshot.data!.data()!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name: ${data['name']}",
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  "Reg No: ${data['regNo']}",
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  "Department: ${data['dept']}",
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  "Phone: ${data['phone']}",
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  "Email: ${data['email']}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
