import 'package:campusease/views/aboutus/about_us_page.dart';
import 'package:campusease/views/chat/global_chat_screen.dart';
import 'package:campusease/views/student/library_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'editable_timetable_page.dart';
import 'teacher_feedback_page.dart';
import 'teacherPollPage.dart';
import 'teacher_poll_results.dart' as pollResults;
import ' internal_marks_page.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? assignedClass;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTeacherClass();
  }

  Future<void> loadTeacherClass() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (mounted) {
      setState(() {
        assignedClass = doc.data()?["assignedClass"] as String?;
        loading = false;
      });
    }
  }

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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        centerTitle: true,
        // ABOUT US ICON (LEFT)
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: "About Us",
          onPressed: () => Get.to(() => const AboutUsPage()),
        ),
        actions: [
          IconButton(
            iconSize: 28,
            tooltip: "Smart AI Assist",
            icon: const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
            onPressed: () => Get.to(() => const LibraryPage()),
          ),
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () => Get.toNamed('/teacherProfile'),
          ),
        ],
      ),

      // --- FIXED GRADIENT GLOW CHAT BUTTON ---
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          focusElevation: 0,
          highlightElevation: 0,
          hoverElevation: 0,
          splashColor: Colors.white24,
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          label: const Text(
            "Class Chat",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            if (assignedClass != null) {
              Get.to(() => GlobalChatScreen(classId: assignedClass!));
            } else {
              Get.snackbar(
                "Error",
                "No class assigned to you yet",
                backgroundColor: Colors.black,
                colorText: Colors.white,
              );
            }
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            buildCard(
              icon: Icons.approval,
              title: "Approve Students",
              subtitle: "Manage department registrations",
              onTap: () => Get.toNamed('/approveStudents'),
            ),

            buildCard(
              icon: Icons.check_circle,
              title: "Take Attendance",
              subtitle: assignedClass ?? "Assign class first",
              onTap: () => Get.toNamed('/attendance'),
            ),

            buildCard(
              icon: Icons.grade,
              title: "Internal Marks",
              subtitle: "Enter and edit class marks",
              onTap: () {
                if (assignedClass != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InternalMarksPage(className: assignedClass!),
                    ),
                  );
                }
              },
            ),

            buildCard(
              icon: Icons.campaign,
              title: "Announcements",
              subtitle: "Create and view announcements",
              onTap: () => Get.toNamed('/teacherAnnouncements'),
            ),

            buildCard(
              icon: Icons.schedule,
              title: "Time Table",
              subtitle: "Manage daily schedules",
              onTap: () {
                if (assignedClass != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditableTimetablePage(className: assignedClass!),
                    ),
                  );
                }
              },
            ),

            buildCard(
              icon: Icons.add_chart,
              title: "Create Poll",
              subtitle: "Start a new class vote",
              onTap: () => Get.to(() => const TeacherPollPage()),
            ),

            buildCard(
              icon: Icons.bar_chart,
              title: "Poll Results",
              subtitle: "View analytics of ended polls",
              onTap: () {
                if (assignedClass != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => pollResults.TeacherPollResultsPage(
                        className: assignedClass!,
                      ),
                    ),
                  );
                }
              },
            ),

            buildCard(
              icon: Icons.feedback,
              title: "Student Feedback",
              subtitle: "View submitted feedback",
              onTap: () {
                if (assignedClass != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TeacherFeedbackPage(className: assignedClass!),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
