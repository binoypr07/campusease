import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Map<String, dynamic>? studentData;
  double attendancePercentage = 0;
  int totalDays = 0;
  int presentDays = 0;

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadAttendance();
  }

  // -----------------------------------------------------------
  // LOAD STUDENT BASIC DETAILS
  // -----------------------------------------------------------
  Future<void> loadProfile() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    var doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        studentData = Map<String, dynamic>.from(doc.data()!); // safe casting
      });
    }
  }

  // -----------------------------------------------------------
  // LOAD ATTENDANCE SUMMARY
  // -----------------------------------------------------------
  Future<void> loadAttendance() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    var doc = await FirebaseFirestore.instance
        .collection("attendance")
        .doc(uid)
        .get();

    if (!doc.exists) return;

    Map<String, dynamic> data = Map<String, dynamic>.from(
      doc.data()!,
    ); // safe cast

    totalDays = data.length;
    presentDays = data.values.where((v) => v == 1.0 || v == 1).length;

    if (totalDays > 0) {
      attendancePercentage = double.parse(
        (presentDays / totalDays * 100).toStringAsFixed(1),
      );
    } else {
      attendancePercentage = 0;
    }

    setState(() {});
  }

  Widget infoTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (studentData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 55, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                studentData!["name"] ?? "",
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // BASIC INFO
            infoTile("Email", studentData!["email"] ?? "-"),
            infoTile("Department", studentData!["department"] ?? "-"),
            infoTile("Class", studentData!["classYear"] ?? "-"),
            infoTile(
              "Admission Number",
              studentData!["admissionNumber"] ?? "-",
            ),
            infoTile("Semester", studentData!["semester"]?.toString() ?? "-"),

            const SizedBox(height: 20),

            // -------------------------------------------------
            // ATTENDANCE SUMMARY
            // -------------------------------------------------
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: const Text(
                  "Attendance Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Days: $totalDays",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Present Days: $presentDays",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Attendance %: $attendancePercentage%",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // -------------------------------------------------
            // INTERNAL MARKS (COMING SOON)
            // -------------------------------------------------
            Card(
              child: ListTile(
                title: const Text(
                  "Internal Marks",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "This feature will be added later...",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
