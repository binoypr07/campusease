import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class TeacherApproveStudents extends StatefulWidget {
  const TeacherApproveStudents({super.key});

  @override
  State<TeacherApproveStudents> createState() => _TeacherApproveStudentsState();
}

class _TeacherApproveStudentsState extends State<TeacherApproveStudents> {
  String? teacherDepartment;

  @override
  void initState() {
    super.initState();
    loadTeacherData();
  }

  // -----------------------------------------------------
  // LOAD TEACHER DEPARTMENT
  // -----------------------------------------------------
  Future<void> loadTeacherData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    var doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (doc.exists) {
      setState(() {
        teacherDepartment = doc["department"];
      });
    }
  }

  // -----------------------------------------------------
  // APPROVE STUDENT
  // -----------------------------------------------------
  Future<void> approveStudent(String uid, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).set(data);
    await FirebaseFirestore.instance.collection("pendingUsers").doc(uid).delete();

    Get.snackbar(
      "Success",
      "Student Approved",
      backgroundColor: Colors.black,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (teacherDepartment == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Approve Students"),
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("pendingUsers")
            .where("role", isEqualTo: "student")
            .where("department", isEqualTo: teacherDepartment)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No pending students in $teacherDepartment",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var user = docs[index];
              var data = user.data();

              return Card(
                color: Colors.black,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white, width: 1.4),
                ),
                child: ListTile(
                  title: Text(
                    data["name"],
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  subtitle: Text(
                    "Admission No: ${data["admissionNumber"]}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => approveStudent(user.id, data),
                    child: const Text("Approve"),
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
