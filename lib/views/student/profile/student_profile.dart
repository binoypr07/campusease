import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  // ─── Cloudinary config ────────────────────────────────────────────────────

  static const String _cloudName = "";
  static const String _uploadPreset = "flutter_profiles";

  // ─── State ────────────────────────────────────────────────────────────────
  Map<String, dynamic>? studentData;
  double attendancePercentage = 0;
  int totalDays = 0;
  int presentDays = 0;
  int halfDays = 0;
  int absentDays = 0;

  String? localImagePath;
  String? cloudImageUrl;

  int currentSemester = 1;
  DateTime? semesterStartDate;
  DateTime? semesterEndDate;

  bool _isUploadingImage = false;

  // ─── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Future.wait([
        loadProfile(user.uid),
        loadLocalProfileImage(user.uid),
      ]);
      await loadAttendance(user.uid);
    } else {
      Get.offAllNamed('/login');
    }
  }

  // ─── Load profile ─────────────────────────────────────────────────────────
  Future<void> loadProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null && mounted) {
        setState(() {
          studentData = Map<String, dynamic>.from(doc.data()!);
          cloudImageUrl = studentData!['profileImageUrl'] as String?;

          // ── NEW: read currentSemester from Firestore (set by teacher End Semester)
          // Falls back to calculating from admission date if not yet set
          if (studentData!['currentSemester'] != null) {
            currentSemester = studentData!['currentSemester'] as int;
          }

          _calculateCurrentSemester();
        });
      }
    } catch (e) {
      debugPrint("Firestore Profile Error: $e");
    }
  }

  // ─── Semester calculation ──────────────────────────────────────────────────
  void _calculateCurrentSemester() {
    if (studentData == null) return;

    // PRIORITY 1: Use exact dates stored by teacher End Semester
    final rawStart = studentData!['semesterStartDate'];
    final rawEnd = studentData!['semesterEndDate'];

    if (rawStart is Timestamp && rawEnd is Timestamp) {
      semesterStartDate = rawStart.toDate();
      semesterEndDate = rawEnd.toDate();
      return;
    }

    // PRIORITY 2: Fall back to calculating from admissionDate
    DateTime admissionDate;
    final raw = studentData!['admissionDate'];
    if (raw is Timestamp) {
      admissionDate = raw.toDate();
    } else if (raw is String) {
      admissionDate = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      admissionDate = DateTime.now();
    }

    if (studentData!['currentSemester'] == null) {
      final now = DateTime.now();
      final monthsSince =
          (now.year - admissionDate.year) * 12 +
          (now.month - admissionDate.month);
      currentSemester = (monthsSince ~/ 6) + 1;
    }

    final semestersCompleted = currentSemester - 1;
    semesterStartDate = DateTime(
      admissionDate.year,
      admissionDate.month + (semestersCompleted * 6),
      admissionDate.day,
    );
    semesterEndDate = DateTime(
      semesterStartDate!.year,
      semesterStartDate!.month + 6,
      semesterStartDate!.day,
    ).subtract(const Duration(days: 1));
  }

  // ─── Load attendance ───────────────────────────────────────────────────────
  Future<void> loadAttendance(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("attendance")
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        if (mounted)
          setState(() {
            totalDays = presentDays = halfDays = absentDays = 0;
            attendancePercentage = 0;
          });
        return;
      }

      final allData = Map<String, dynamic>.from(doc.data()!);
      final semesterData = <String, dynamic>{};

      if (semesterStartDate != null && semesterEndDate != null) {
        allData.forEach((dateStr, value) {
          try {
            final date = DateFormat('yyyy-MM-dd').parse(dateStr);
            if (!date.isBefore(semesterStartDate!) &&
                !date.isAfter(semesterEndDate!)) {
              semesterData[dateStr] = value;
            }
          } catch (_) {}
        });
      } else {
        semesterData.addAll(allData);
      }

      totalDays = semesterData.length;
      presentDays = semesterData.values.where((v) => v == 1.0 || v == 1).length;
      halfDays = semesterData.values.where((v) => v == 0.5).length;
      absentDays = semesterData.values.where((v) => v == 0.0 || v == 0).length;

      attendancePercentage = totalDays > 0
          ? double.parse(
              ((presentDays + 0.5 * halfDays) / totalDays * 100)
                  .toStringAsFixed(1),
            )
          : 0;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Attendance Error: $e");
      if (mounted)
        setState(() {
          totalDays = presentDays = halfDays = absentDays = 0;
          attendancePercentage = 0;
        });
    }
  }

  // ─── Cloudinary upload ────────────────────────────────────────────────────
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

    if (streamed.statusCode == 200) {
      return json['secure_url'] as String?;
    }
    debugPrint("Cloudinary error: ${json['error']?['message']}");
    return null;
  }

  // ─── Save image locally (cache) ───────────────────────────────────────────
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

  // ─── Pick + upload image ──────────────────────────────────────────────────
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

  // ─── Delete profile image ─────────────────────────────────────────────────
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

  // ─── Image options bottom sheet ───────────────────────────────────────────
  void _showImageOptions() {
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

  // ─── Build ─────────────────────────────────────────────────────────────────
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
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: "Logout",
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar ──
          Center(
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _showImageOptions,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
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
                  if (_isUploadingImage)
                    const Positioned.fill(
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.black54,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
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
          const SizedBox(height: 6),
          Center(
            child: Text(
              _isUploadingImage ? "Uploading…" : "Tap to change photo",
              style: const TextStyle(color: Colors.white54, fontSize: 12),
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

          // ── Info tiles ──
          _infoTile("Email", studentData!["email"] ?? "-"),
          _infoTile("Department", studentData!["department"] ?? "-"),
          _infoTile("Class", studentData!["classYear"] ?? "-"),
          _infoTile("Admission Number", studentData!["admissionNumber"] ?? "-"),
          _infoTile("Semester (6-month cycle)", "Semester $currentSemester"),
          // ── NEW: Attendance % tile for current semester ──
          _infoTile(
            "Attendance (Semester $currentSemester)",
            totalDays > 0 ? "$attendancePercentage%" : "No data yet",
          ),

          if (semesterStartDate != null && semesterEndDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "Period: ${DateFormat('dd MMM yyyy').format(semesterStartDate!)} "
                "– ${DateFormat('dd MMM yyyy').format(semesterEndDate!)}",
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 20),

          // ── Attendance card ──
          _buildAttendanceCard(),
        ],
      ),
    );
  }

  // ─── Avatar image provider ─────────────────────────────────────────────────
  ImageProvider? _avatarImage() {
    if (localImagePath != null && File(localImagePath!).existsSync()) {
      return FileImage(File(localImagePath!));
    }
    if (cloudImageUrl != null) {
      return NetworkImage(cloudImageUrl!);
    }
    return null;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _infoTile(String label, String value, {VoidCallback? onTap}) {
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
        trailing: onTap != null
            ? const Icon(Icons.edit, color: Colors.blueAccent, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Card(
      color: const Color(0xFF1F2C34),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Attendance Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  child: Text(
                    "Semester $currentSemester",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCol("Working\nDays", totalDays.toString(), Colors.blue),
                _statCol("Present", presentDays.toString(), Colors.green),
                _statCol("Half\nDays", halfDays.toString(), Colors.orange),
                _statCol("Absent", absentDays.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  const Text(
                    "Attendance Percentage",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalDays > 0 ? "$attendancePercentage%" : "No data",
                    style: TextStyle(
                      color: _percentageColor(attendancePercentage),
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  if (totalDays > 0) const SizedBox(height: 8),
                  if (totalDays > 0)
                    const Text(
                      "Formula: (Present + 0.5 × Half Days) ÷ Working Days",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    ],
  );

  Color _percentageColor(double p) => p >= 75
      ? Colors.green
      : p >= 60
      ? Colors.orange
      : Colors.red;

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
