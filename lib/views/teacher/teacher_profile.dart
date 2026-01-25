import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:image_picker/image_picker.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  Map<String, dynamic>? teacherData;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    var doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        teacherData = doc.data();
      });
    }
  }

  // -----------------------------------------------------------
  // PICK IMAGE + UPLOAD (same as Student)
  // -----------------------------------------------------------
  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    String uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.jpg');

    await ref.putFile(File(pickedFile.path));
    String imageUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profileImage': imageUrl,
    });

    loadProfile(); // refresh UI
  }

  Widget infoTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white, width: 1.4),
      ),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 17, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (teacherData == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
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
              icon: const Icon(Icons.logout_rounded),
              tooltip: "Logout",
              onPressed: () {
                Get.defaultDialog(
                  title: "Confirm Logout",
                  middleText: "Are you sure you want to logout?",
                  radius: 14,
                  textCancel: "Cancel",
                  textConfirm: "Logout",
                  cancelTextColor: const Color.fromARGB(255, 227, 219, 219),
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.redAccent,
                  onConfirm: () {
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
            const SizedBox(height: 10),

            // ---------- PROFILE PICTURE (UPDATED ONLY) ----------
            Center(
              child: GestureDetector(
                onTap: pickAndUploadImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      teacherData!["profileImage"] != null &&
                          teacherData!["profileImage"].toString().isNotEmpty
                      ? NetworkImage(teacherData!["profileImage"])
                      : null,
                  child:
                      teacherData!["profileImage"] == null ||
                          teacherData!["profileImage"].toString().isEmpty
                      ? const Icon(Icons.person, size: 55, color: Colors.black)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---------- TEACHER NAME ----------
            Center(
              child: Text(
                teacherData!["name"] ?? "",
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ---------- INFORMATION TILES ----------
            infoTile("Email", teacherData!["email"] ?? "-"),
            infoTile("Department", teacherData!["department"] ?? "-"),
            infoTile("Teacher ID", teacherData!["teacherId"] ?? "-"),
            infoTile(
              "Assigned Class",
              teacherData!["assignedClass"] ?? "Not Assigned",
            ),

            const SizedBox(height: 10),

            // ---------- SUBJECT LIST ----------
            Card(
              margin: const EdgeInsets.only(top: 12),
              color: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white, width: 1.4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Subjects",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List<Widget>.from(
                        (teacherData!["subjects"] ?? []).map(
                          (subject) => Chip(
                            backgroundColor: Colors.white,
                            label: Text(
                              subject,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
