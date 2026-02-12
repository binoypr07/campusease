import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  Map<String, dynamic>? teacherData;
  bool isUploading = false; // Track upload state

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      var doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (doc.exists) {
        setState(() {
          teacherData = doc.data();
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load profile: $e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return;

    setState(() => isUploading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref().child('profile_images').child('$uid.jpg');

      await ref.putFile(File(pickedFile.path));
      String imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImage': imageUrl,
      });

      await loadProfile();
      Get.snackbar("Success", "Profile picture updated!");
    } catch (e) {
      Get.snackbar("Upload Failed", e.toString());
    } finally {
      setState(() => isUploading = false);
    }
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
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        subtitle: Text(value, style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w500)),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text("Teacher Profile", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => Get.defaultDialog(
              title: "Logout",
              middleText: "Are you sure you want to sign out?",
              textConfirm: "Logout",
              confirmTextColor: Colors.white,
              onConfirm: () async {
                await FirebaseAuth.instance.signOut();
                Get.offAllNamed('/login');
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------- PROFILE PICTURE ----------
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[900],
                    backgroundImage: (teacherData!["profileImage"]?.toString().isNotEmpty ?? false)
                        ? NetworkImage(teacherData!["profileImage"])
                        : null,
                    child: (teacherData!["profileImage"]?.toString().isEmpty ?? true)
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  if (isUploading)
                    const Positioned.fill(child: CircularProgressIndicator(color: Colors.blueAccent)),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: pickAndUploadImage,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(teacherData!["name"] ?? "Teacher Name",
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            infoTile("Email", teacherData!["email"] ?? "-"),
            infoTile("Department", teacherData!["department"] ?? "-"),
            infoTile("Teacher ID", teacherData!["teacherId"] ?? "-"),
            infoTile("Assigned Class", teacherData!["assignedClass"] ?? "Not Assigned"),

            // ---------- SUBJECTS ----------
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text("Subjects Handled", style: TextStyle(color: Colors.white.withOpacity(0.6))),
              ),
            ),
            Wrap(
              spacing: 8,
              children: (teacherData!["subjects"] as List? ?? []).map((s) => Chip(
                label: Text(s.toString()),
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}