import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  Map<String, dynamic>? teacherData;
  bool isUploading = false;
  String? localImagePath; //  local image path like student profile

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadLocalProfileImage(); // ADDED
  }

  Future<void> loadProfile() async {
    try {
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
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load profile: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  //  Load local profile image (same as student profile)
  Future<void> loadLocalProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String? savedPath = prefs.getString('profile_image_${user.uid}');

      if (savedPath != null && await File(savedPath).exists()) {
        if (mounted) {
          setState(() {
            localImagePath = savedPath;
          });
        }
      } else {
        if (savedPath != null) {
          await prefs.remove('profile_image_${user.uid}');
        }
      }
    }
  }

  //  Pick from gallery and save locally (same as student profile)
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

    try {
      final directory = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${directory.path}/profiles');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      String localPath = '${profileDir.path}/${uid}_profile.jpg';

      File oldImage = File(localPath);
      if (await oldImage.exists()) {
        await oldImage.delete();
      }

      File sourceFile = File(pickedFile.path);
      await sourceFile.copy(localPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_$uid', localPath);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'hasProfileImage': true,
        'profileImageUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          localImagePath = localPath;
        });
      }

      Get.snackbar(
        "Success",
        "Profile image saved locally!",
        colorText: Colors.white,
        backgroundColor: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save image: $e",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Pick from camera and save locally (same as student profile)
  Future<void> pickFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String uid = user.uid;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${directory.path}/profiles');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      String localPath = '${profileDir.path}/${uid}_profile.jpg';

      File oldImage = File(localPath);
      if (await oldImage.exists()) {
        await oldImage.delete();
      }

      File sourceFile = File(pickedFile.path);
      await sourceFile.copy(localPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_$uid', localPath);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'hasProfileImage': true,
        'profileImageUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          localImagePath = localPath;
        });
      }

      Get.snackbar(
        "Success",
        "Photo saved locally!",
        colorText: Colors.white,
        backgroundColor: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save photo: $e",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Delete local profile image (same as student profile)
  Future<void> deleteProfileImage() async {
    if (localImagePath == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      File imageFile = File(localImagePath!);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_${user.uid}');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'hasProfileImage': false},
      );

      if (mounted) {
        setState(() {
          localImagePath = null;
        });
      }

      Get.snackbar(
        "Deleted",
        "Profile image removed",
        colorText: Colors.white,
        backgroundColor: Colors.orange,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete image: $e",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Show image options bottom sheet (same as student profile)
  void showImageOptions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2C34),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Get.back();
                  pickAndUploadImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Get.back();
                  pickFromCamera();
                },
              ),
              if (localImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Get.back();
                    deleteProfileImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
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
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Teacher Profile",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile picture — now uses local image like student profile
            Center(
              child: GestureDetector(
                onTap: showImageOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: localImagePath != null
                          ? FileImage(File(localImagePath!))
                          : null,
                      child: localImagePath == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.white54,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A884),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Tap to change photo',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              teacherData!["name"] ?? "Teacher Name",
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            infoTile("Email", teacherData!["email"] ?? "-"),
            infoTile("Department", teacherData!["department"] ?? "-"),
            infoTile("Teacher ID", teacherData!["teacherId"] ?? "-"),
            infoTile(
              "Assigned Class",
              teacherData!["assignedClass"] ?? "Not Assigned",
            ),

            // ---------- SUBJECTS ----------
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "Subjects Handled",
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              children: (teacherData!["subjects"] as List? ?? [])
                  .map(
                    (s) => Chip(
                      label: Text(s.toString()),
                      backgroundColor: Colors.white,
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
