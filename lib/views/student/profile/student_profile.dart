import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
    _initData();
  }

  // Combined loading to ensure UID is valid before any Firestore call
  Future<void> _initData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await loadProfile(user.uid);
      await loadAttendance(user.uid);
    } else {
      print("Error: No user logged in.");
      Get.offAllNamed('/login');
    }
  }

  // -----------------------------------------------------------
  // LOAD STUDENT BASIC DETAILS
  // -----------------------------------------------------------
  Future<void> loadProfile(String uid) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            studentData = Map<String, dynamic>.from(doc.data()!);
          });
        }
      }
    } catch (e) {
      print("Firestore Profile Error: $e");
    }
  }

  // -----------------------------------------------------------
  // LOAD ATTENDANCE SUMMARY - FIXED CRASH POINT
  // -----------------------------------------------------------
  Future<void> loadAttendance(String uid) async {
    try {
      // The specific line that was crashing:
      var doc = await FirebaseFirestore.instance
          .collection("attendance")
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        print("Attendance document does not exist for $uid");
        return;
      }

      Map<String, dynamic> data = Map<String, dynamic>.from(doc.data()!);

      // Safe calculation logic
      totalDays = data.length;
      presentDays = data.values.where((v) {
        String val = v.toString();
        return val == "1.0" || val == "1";
      }).length;

      if (totalDays > 0) {
        attendancePercentage = double.parse(
          (presentDays / totalDays * 100).toStringAsFixed(1),
        );
      } else {
        attendancePercentage = 0;
      }

      if (mounted) setState(() {});
    } catch (e) {
      // This catches the crash and prevents the app from closing
      print("Firestore Attendance Error: $e");
      if (mounted) {
        setState(() {
          totalDays = 0;
          presentDays = 0;
          attendancePercentage = 0;
        });
      }
    }
  }

  // -----------------------------------------------------------
  // PICK IMAGE + UPLOAD TO FIREBASE
  // -----------------------------------------------------------
  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String uid = user.uid;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.jpg');

    try {
      await ref.putFile(File(pickedFile.path));
      String imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImage': imageUrl,
      });

      loadProfile(uid);
    } catch (e) {
      Get.snackbar("Error", "Failed to upload image", colorText: Colors.white);
    }
  }

  Widget infoTile(String label, String value) {
    return Card(
      color: const Color(0xFF1F2C34),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
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
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: "Logout",
              onPressed: () {
                Get.defaultDialog(
                  backgroundColor: const Color(0xFF1F2C34),
                  titleStyle: const TextStyle(color: Colors.white),
                  title: "Confirm Logout",
                  content: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Are you sure you want to logout?",
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  radius: 14,
                  textCancel: "Cancel",
                  textConfirm: "Logout",
                  cancelTextColor: Colors.white,
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.redAccent,
                  onConfirm: () async {
                    await FirebaseAuth.instance.signOut();
                    Get.offAllNamed('/login');
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: pickAndUploadImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[800],
                  backgroundImage:
                      studentData!["profileImage"] != null &&
                          studentData!["profileImage"].toString().isNotEmpty
                      ? NetworkImage(studentData!["profileImage"])
                      : null,
                  child:
                      studentData!["profileImage"] == null ||
                          studentData!["profileImage"].toString().isEmpty
                      ? const Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.white54,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                studentData!["name"] ?? "No Name",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            infoTile("Email", studentData!["email"] ?? "-"),
            infoTile("Department", studentData!["department"] ?? "-"),
            infoTile("Class", studentData!["classYear"] ?? "-"),
            infoTile(
              "Admission Number",
              studentData!["admissionNumber"] ?? "-",
            ),
            infoTile("Semester", studentData!["semester"]?.toString() ?? "-"),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFF1F2C34),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: const Text(
                  "Attendance Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Days: $totalDays",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Present Days: $presentDays",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Attendance %: $attendancePercentage%",
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
