import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  int halfDays = 0;
  int absentDays = 0;
  String? localImagePath;
  int currentSemester = 1;
  DateTime? semesterStartDate;
  DateTime? semesterEndDate;

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
      await loadLocalProfileImage();
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
            // Calculate current semester based on admission date
            _calculateCurrentSemester();
          });
        }
      }
    } catch (e) {
      print("Firestore Profile Error: $e");
    }
  }

  // -----------------------------------------------------------
  // CALCULATE CURRENT SEMESTER (6-month cycles)
  // -----------------------------------------------------------
  void _calculateCurrentSemester() {
    if (studentData == null) return;

    // Get admission date from student data
    DateTime admissionDate;

    if (studentData!['admissionDate'] != null) {
      // If stored as Timestamp
      if (studentData!['admissionDate'] is Timestamp) {
        admissionDate = (studentData!['admissionDate'] as Timestamp).toDate();
      }
      // If stored as String
      else if (studentData!['admissionDate'] is String) {
        try {
          admissionDate = DateTime.parse(studentData!['admissionDate']);
        } catch (e) {
          admissionDate = DateTime.now();
        }
      } else {
        admissionDate = DateTime.now();
      }
    } else {
      // Default to current date if no admission date
      admissionDate = DateTime.now();
    }

    DateTime now = DateTime.now();

    // Calculate months since admission
    int monthsSinceAdmission =
        (now.year - admissionDate.year) * 12 +
        (now.month - admissionDate.month);

    // Calculate semester (6 months = 1 semester)
    currentSemester = (monthsSinceAdmission ~/ 6) + 1;

    // Calculate current semester start and end dates
    int semestersCompleted = currentSemester - 1;
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

    print("Admission Date: $admissionDate");
    print("Current Semester: $currentSemester");
    print("Semester Start: $semesterStartDate");
    print("Semester End: $semesterEndDate");
  }

  // -----------------------------------------------------------
  // LOAD ATTENDANCE FOR CURRENT SEMESTER ONLY
  // -----------------------------------------------------------
  Future<void> loadAttendance(String uid) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection("attendance")
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        print("Attendance document does not exist for $uid");
        if (mounted) {
          setState(() {
            totalDays = 0;
            presentDays = 0;
            halfDays = 0;
            absentDays = 0;
            attendancePercentage = 0;
          });
        }
        return;
      }

      Map<String, dynamic> allData = Map<String, dynamic>.from(doc.data()!);

      // Filter attendance data for current semester only
      Map<String, dynamic> semesterData = {};

      if (semesterStartDate != null && semesterEndDate != null) {
        allData.forEach((dateStr, value) {
          try {
            DateTime date = DateFormat('yyyy-MM-dd').parse(dateStr);

            // Check if date is within current semester
            if (date.isAfter(
                  semesterStartDate!.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(semesterEndDate!.add(const Duration(days: 1)))) {
              semesterData[dateStr] = value;
            }
          } catch (e) {
            print("Date parse error for $dateStr: $e");
          }
        });
      } else {
        // If no semester dates, use all data
        semesterData = allData;
      }

      print("Total attendance records: ${allData.length}");
      print("Current semester records: ${semesterData.length}");

      // Calculate total working days (all entries in current semester)
      totalDays = semesterData.length;

      // Count present days (value == 1.0 or 1)
      presentDays = semesterData.values.where((v) {
        if (v == null) return false;
        return v == 1.0 || v == 1;
      }).length;

      // Count half days (value == 0.5)
      halfDays = semesterData.values.where((v) {
        if (v == null) return false;
        return v == 0.5;
      }).length;

      // Count absent days (value == 0.0 or 0)
      absentDays = semesterData.values.where((v) {
        if (v == null) return false;
        return v == 0.0 || v == 0;
      }).length;

      // Calculate attendance percentage
      // Formula: (Present + 0.5 * Half Days) / Total Days * 100
      if (totalDays > 0) {
        double effectiveDays = presentDays + (0.5 * halfDays);
        attendancePercentage = double.parse(
          (effectiveDays / totalDays * 100).toStringAsFixed(1),
        );
      } else {
        attendancePercentage = 0;
      }

      if (mounted) setState(() {});
    } catch (e) {
      print("Firestore Attendance Error: $e");
      if (mounted) {
        setState(() {
          totalDays = 0;
          presentDays = 0;
          halfDays = 0;
          absentDays = 0;
          attendancePercentage = 0;
        });
      }
    }
  }

  // -----------------------------------------------------------
  // MANUALLY CHANGE SEMESTER
  // -----------------------------------------------------------
  void _showChangeSemesterDialog() {
    int newSemester = currentSemester;

    Get.defaultDialog(
      backgroundColor: const Color(0xFF1F2C34),
      titleStyle: const TextStyle(color: Colors.white),
      title: "Change Semester",
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            children: [
              const Text(
                "Select Semester (6-month cycle)",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      if (newSemester > 1) {
                        setDialogState(() => newSemester--);
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Semester $newSemester",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      if (newSemester < 12) {
                        setDialogState(() => newSemester++);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Current: Semester $currentSemester",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          );
        },
      ),
      textCancel: "Cancel",
      textConfirm: "Update",
      cancelTextColor: Colors.white,
      confirmTextColor: Colors.white,
      buttonColor: Colors.blueAccent,
      onConfirm: () async {
        if (newSemester != currentSemester) {
          await _updateSemester(newSemester);
        }
        Get.back();
      },
    );
  }

  // -----------------------------------------------------------
  // UPDATE SEMESTER IN FIRESTORE
  // -----------------------------------------------------------
  Future<void> _updateSemester(int newSemester) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'semester': newSemester},
      );

      setState(() {
        currentSemester = newSemester;
      });

      // Recalculate semester dates
      _calculateCurrentSemester();

      // Reload attendance for new semester
      await loadAttendance(user.uid);

      Get.snackbar(
        "Success",
        "Semester updated to $newSemester",
        colorText: Colors.white,
        backgroundColor: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update semester: $e",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // -----------------------------------------------------------
  // LOAD LOCAL PROFILE IMAGE
  // -----------------------------------------------------------
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

  // -----------------------------------------------------------
  // PICK IMAGE + SAVE LOCALLY (NO FIREBASE UPLOAD)
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

  // -----------------------------------------------------------
  // PICK FROM CAMERA
  // -----------------------------------------------------------
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

  // -----------------------------------------------------------
  // DELETE PROFILE IMAGE
  // -----------------------------------------------------------
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

  // -----------------------------------------------------------
  // SHOW IMAGE OPTIONS DIALOG
  // -----------------------------------------------------------
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

  Widget infoTile(String label, String value, {VoidCallback? onTap}) {
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
            // Profile Image
            Center(
              child: GestureDetector(
                onTap: showImageOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
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

            // User Info
            infoTile("Email", studentData!["email"] ?? "-"),
            infoTile("Department", studentData!["department"] ?? "-"),
            infoTile("Class", studentData!["classYear"] ?? "-"),
            infoTile(
              "Admission Number",
              studentData!["admissionNumber"] ?? "-",
            ),

            // Semester with edit option
            infoTile(
              "Semester (6-month cycle)",
              "Semester $currentSemester",
              onTap: _showChangeSemesterDialog,
            ),

            // Show semester date range
            if (semesterStartDate != null && semesterEndDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "Period: ${DateFormat('dd MMM yyyy').format(semesterStartDate!)} - ${DateFormat('dd MMM yyyy').format(semesterEndDate!)}",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            // Attendance Summary Card
            Card(
              color: const Color(0xFF1F2C34),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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

                    // Stats Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          "Working\nDays",
                          totalDays.toString(),
                          Colors.blue,
                        ),
                        _buildStatColumn(
                          "Present",
                          presentDays.toString(),
                          Colors.green,
                        ),
                        _buildStatColumn(
                          "Half\nDays",
                          halfDays.toString(),
                          Colors.orange,
                        ),
                        _buildStatColumn(
                          "Absent",
                          absentDays.toString(),
                          Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    // Attendance Percentage
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            "Attendance Percentage",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalDays > 0
                                ? "$attendancePercentage%"
                                : "No data",
                            style: TextStyle(
                              color: _getPercentageColor(attendancePercentage),
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Formula explanation
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
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for stat columns
  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
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
  }

  // Get color based on attendance percentage
  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}
