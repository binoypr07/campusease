import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr.dart';
import 'timetable_page.dart';
import 'feedback_page.dart';
import 'polls_page.dart';
import 'student_internal_marks.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  // ---------------------------------------------------------
  // REUSABLE CARD WIDGET
  // ---------------------------------------------------------
  Widget buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: onTap,
      ),
    );
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Student data not found',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final studentId = data['admissionNumber'] ?? 'No ID';
        final studentName = data['name'] ?? 'No Name';
        final studentPhone = data['phone'] ?? 'No Phone';
        final studentDepartment = data['department'] ?? 'No Department';
        final studentClass = data['classYear'] ?? '';
        final studentSemester = data['semester'] ?? 1;

        // -------------------- FIX HERE --------------------
        final assignedClass =
            data['classYear'] ??
            ''; // <-- use classYear instead of assignedClass
        print("DEBUG: assignedClass after toString → $assignedClass");
        print("DEBUG: full student data → $data");
        // -------------------------------------------------

        return Scaffold(
          appBar: AppBar(
            title: const Text("Student Dashboard"),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const SizedBox(height: 10),

                // ------------------ PROFILE ------------------
                buildCard(
                  icon: Icons.person,
                  title: "My Profile",
                  subtitle: "View personal details",
                  onTap: () => Get.toNamed('/studentProfile'),
                ),

                // ------------------ ATTENDANCE ------------------
                buildCard(
                  icon: Icons.calendar_month,
                  title: "Attendance",
                  subtitle: "View your attendance",
                  onTap: () => Get.toNamed('/studentAttendance'),
                ),

                // ------------------ INTERNAL MARKS ------------------
                buildCard(
                  icon: Icons.grade,
                  title: "Internal Marks",
                  subtitle: "View your marks",
                  onTap: () {
                    final assignedClass = data['classYear'] ?? '';
                    if (assignedClass.isEmpty) {
                      Get.snackbar(
                        "Class Not Assigned",
                        "Your class is not assigned yet",
                        backgroundColor: Colors.black,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentInternalMarks(className: assignedClass),
                      ),
                    );
                  },
                ),

                // ------------------ Time Table------------------
                buildCard(
                  icon: Icons.schedule,
                  title: "Time Table",
                  subtitle: "View your daily schedule",
                  onTap: () {
                    print("DEBUG: assignedClass = $assignedClass");

                    if (assignedClass.isEmpty) {
                      Get.snackbar(
                        "Class Not Assigned",
                        "Your class is not assigned yet",
                        backgroundColor: Colors.black,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TimetablePage(className: assignedClass),
                      ),
                    );
                  },
                ),

                // ------------------ ANNOUNCEMENTS ------------------
                buildCard(
                  icon: Icons.notifications,
                  title: "Announcements",
                  subtitle: "Notices from teachers & admin",
                  onTap: () => Get.toNamed('/studentAnnouncements'),
                ),

                // ------------------ QR CODE ------------------
                buildCard(
                  icon: Icons.qr_code,
                  title: "My QR Code",
                  subtitle: "Show your student QR",
                  onTap: () {
                    Get.to(
                      () => StudentQRPage(
                        studentId: studentId,
                        studentName: studentName,
                        phone: studentPhone,
                        department: studentDepartment,
                        classYear: studentClass,
                        semester: studentSemester,
                      ),
                    );
                  },
                ),
                // ------------------ FEEDBACK ------------------
                buildCard(
                  icon: Icons.feedback,
                  title: "Feedback",
                  subtitle: "Send feedback to teachers/admin",
                  onTap: () {
                    Get.to(
                      () => FeedbackPage(
                        studentId: studentId,
                        studentName: studentName,
                        classYear: studentClass,
                      ),
                    );
                  },
                ),

                // ------------------ POLL ------------------
                buildCard(
                  icon: Icons.poll,
                  title: "Polls",
                  subtitle: "Participate in active polls",
                  onTap: () {
                    Get.to(
                      () => PollsPage(
                        studentId: studentId,
                        classYear: studentClass,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ------------------ LOGOUT ------------------
                ElevatedButton(
                  onPressed: () {
                    Get.offAllNamed('/login');
                  },
                  child: const Text("Logout"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
