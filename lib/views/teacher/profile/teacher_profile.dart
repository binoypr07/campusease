import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  // ─── Cloudinary config ─────────────────────────────────────────────────────
  static const String _cloudName = "";
  static const String _uploadPreset = "flutter_profiles";

  // ─── State ─────────────────────────────────────────────────────────────────
  Map<String, dynamic>? teacherData;
  String? localImagePath;
  String? cloudImageUrl;
  bool _isUploadingImage = false;

  // ─── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAllNamed('/login');
      return;
    }
    await Future.wait([loadProfile(user.uid), loadLocalProfileImage(user.uid)]);
  }

  // ─── Load profile ──────────────────────────────────────────────────────────
  Future<void> loadProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null && mounted) {
        setState(() {
          teacherData = Map<String, dynamic>.from(doc.data()!);
          cloudImageUrl = teacherData!['profileImageUrl'] as String?;
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

  // ─── Load local cache ──────────────────────────────────────────────────────
  Future<void> loadLocalProfileImage(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profile_image_$uid');

    if (savedPath != null && await File(savedPath).exists()) {
      if (mounted) setState(() => localImagePath = savedPath);
    } else if (savedPath != null) {
      await prefs.remove('profile_image_$uid');
    }
  }

  // ─── Cloudinary upload ─────────────────────────────────────────────────────
  Future<String?> _uploadToCloudinary(String filePath) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final bytes = await streamed.stream.toBytes();
    final json = jsonDecode(String.fromCharCodes(bytes));

    if (streamed.statusCode == 200) return json['secure_url'] as String?;
    debugPrint("Cloudinary error: ${json['error']?['message']}");
    return null;
  }

  // ─── Save image locally (cache) ────────────────────────────────────────────
  Future<String> _saveImageLocally(String sourcePath, String uid) async {
    final dir = await getApplicationDocumentsDirectory();
    final profileDir = Directory('${dir.path}/profiles');
    if (!await profileDir.exists()) await profileDir.create(recursive: true);

    final localPath = '${profileDir.path}/${uid}_profile.jpg';
    final old = File(localPath);
    if (await old.exists()) await old.delete();
    await File(sourcePath).copy(localPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_$uid', localPath);
    return localPath;
  }

  // ─── Pick + upload image ───────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploadingImage = true);

    try {
      // 1. Upload to Cloudinary
      final url = await _uploadToCloudinary(picked.path);
      if (url == null) throw Exception("Cloudinary upload returned null URL");

      // 2. Save URL to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'profileImageUrl': url,
          'profileImageUpdated': FieldValue.serverTimestamp(),
        },
      );

      // 3. Cache locally
      final localPath = await _saveImageLocally(picked.path, user.uid);

      if (mounted)
        setState(() {
          cloudImageUrl = url;
          localImagePath = localPath;
        });

      Get.snackbar(
        "Success",
        "Profile photo updated!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to upload: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ─── Delete profile image ──────────────────────────────────────────────────
  Future<void> _deleteProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (localImagePath != null) {
        final f = File(localImagePath!);
        if (await f.exists()) await f.delete();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_${user.uid}');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImageUrl': FieldValue.delete()},
      );

      if (mounted)
        setState(() {
          localImagePath = null;
          cloudImageUrl = null;
        });

      Get.snackbar(
        "Removed",
        "Profile photo removed",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to remove image: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ─── Image options bottom sheet ────────────────────────────────────────────
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
                  _pickImage(ImageSource.gallery);
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
                  _pickImage(ImageSource.camera);
                },
              ),
              if (cloudImageUrl != null || localImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Get.back();
                    _deleteProfileImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: Get.back,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Avatar image provider ─────────────────────────────────────────────────
  ImageProvider? _avatarImage() {
    if (localImagePath != null && File(localImagePath!).existsSync()) {
      return FileImage(File(localImagePath!));
    }
    if (cloudImageUrl != null) return NetworkImage(cloudImageUrl!);
    return null;
  }

  // ─── Info tile ─────────────────────────────────────────────────────────────
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

  // ─── Build ─────────────────────────────────────────────────────────────────
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
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Avatar ──
            Center(
              child: GestureDetector(
                onTap: _isUploadingImage ? null : showImageOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _avatarImage(),
                      child: _avatarImage() == null && !_isUploadingImage
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.white54,
                            )
                          : null,
                    ),
                    // Upload spinner overlay
                    if (_isUploadingImage)
                      const Positioned.fill(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.black54,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    // Edit badge
                    if (!_isUploadingImage)
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
            Center(
              child: Text(
                _isUploadingImage ? "Uploading…" : "Tap to change photo",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
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

            // ── Subjects ──
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
              runSpacing: 6,
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

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Logout confirm ────────────────────────────────────────────────────────
  void _confirmLogout() {
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
  }
}
