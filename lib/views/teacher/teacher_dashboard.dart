import 'package:campusease/views/student/global_chat_screen.dart';
import 'package:campusease/views/student/library_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'editable_timetable_page.dart';
import 'teacher_feedback_page.dart';
import 'teacherPollPage.dart';
import 'teacher_poll_results.dart';
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

  // ------------------- UPDATE THIS FUNCTION -------------------
  Future<void> loadTeacherClass() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    var doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    // Safely read assignedClass without crashing
    setState(() {
      assignedClass = doc.data()?["assignedClass"] as String?;
      loading = false;
    });

    // Debugging: check if class is loaded
    print("Assigned class: $assignedClass");
  }

  Widget buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
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
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
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
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        centerTitle: true,
        actions: [
          //AI
          IconButton(
            iconSize: 28,
            tooltip: "Smart AI Assist",
            icon: const Icon(
              Icons.auto_awesome,
              color: Color.fromARGB(255, 89, 64, 251),
            ),
            onPressed: () {
              Get.to(() => const LibraryPage());
            },
          ),
          IconButton(
            iconSize: 28,
            tooltip: "My profile",
            icon: const Icon(Icons.person),
            onPressed: () {
              Get.toNamed('/teacherProfile');
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // APPROVE STUDENTS
            buildCard(
              icon: Icons.approval,
              title: "Approve Students",
              subtitle: "Approve students from your department",
              onTap: () => Get.toNamed('/approveStudents'),
            ),

            // TAKE ATTENDANCE
            buildCard(
              icon: Icons.check_circle,
              title: "Take Attendance",
              subtitle: assignedClass == null || assignedClass!.isEmpty
                  ? "Assign class first"
                  : "Class: $assignedClass",
              onTap: () {
                if (assignedClass == null || assignedClass!.isEmpty) {
                  Get.snackbar(
                    "Class Not Assigned",
                    "Please assign a class first!",
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                } else {
                  Get.toNamed('/attendance');
                }
              },
            ),
            // ------------------ INTERNAL MARKS ------------------
            buildCard(
              icon: Icons.grade,
              title: "Internal Marks",
              subtitle: assignedClass == null || assignedClass!.isEmpty
                  ? "Assign class first"
                  : "Enter marks for your class",
              onTap: () {
                if (assignedClass == null || assignedClass!.isEmpty) {
                  Get.snackbar(
                    "Class Not Assigned",
                    "Please assign a class first!",
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InternalMarksPage(className: assignedClass!),
                  ),
                );
              },
            ),

            // ANNOUNCEMENTS
            buildCard(
              icon: Icons.campaign,
              title: "Announcements",
              subtitle: "create & view",
              onTap: () => Get.toNamed('/teacherAnnouncements'),
            ),

            // ------------------ Time Table ------------------
            buildCard(
              icon: Icons.schedule,
              title: "Time Table",
              subtitle: (assignedClass == null || assignedClass!.isEmpty)
                  ? "Assign class first"
                  : "Edit your class timetable",
              onTap: () {
                if (assignedClass == null || assignedClass!.isEmpty) {
                  Get.snackbar(
                    "Class Not Assigned",
                    "Please assign a class first!",
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                  return; // stop here if no class assigned
                }

                // Navigate to EditableTimetablePage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditableTimetablePage(className: assignedClass!),
                  ),
                );
              },
            ),

            //  ASSIGN CLASS (ONLY IF NOT ASSIGNED)
            if (assignedClass == null || assignedClass!.isEmpty)
              buildCard(
                icon: Icons.class_,
                title: "Assign Class",
                subtitle: "Select your class",
                onTap: () => Get.toNamed('/assignClass'),
              ),
            // ------------------ CREATE POLL ------------------
            buildCard(
              icon: Icons.add_chart,
              title: "Create Poll",
              subtitle: "Create new poll for your class",
              onTap: () {
                if (assignedClass == null || assignedClass!.isEmpty) {
                  Get.snackbar(
                    "Class Not Assigned",
                    "Please assign a class first!",
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherPollPage(), // teacher creates poll
                  ),
                );
              },
            ),

            // ------------------ VIEW POLL RESULTS ------------------
            buildCard(
              icon: Icons.bar_chart,
              title: "Poll Results",
              subtitle: "View results of ended polls",
              onTap: () {
                if (assignedClass == null || assignedClass!.isEmpty) {
                  Get.snackbar(
                    "Class Not Assigned",
                    "Please assign a class first!",
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TeacherPollResultsPage(className: assignedClass!),
                  ),
                );
              },
            ),
            // ------------------ FEEDBACK ------------------
            buildCard(
              icon: Icons.feedback,
              title: "Student Feedback",
              subtitle: "View submitted feedback",
              onTap: () {
                if (assignedClass == null || assignedClass!.isEmpty) {
                  Get.snackbar(
                    "Class Not Assigned",
                    "Please assign a class first!",
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TeacherFeedbackPage(className: assignedClass!),
                  ),
                );
              },
            ),
            // ------------------ CLASS CHAT ------------------
            buildCard(
              icon: Icons.chat_bubble_outline,
              title: "Class Chat",
              subtitle: assignedClass == null || assignedClass!.isEmpty
                  ? "Assign class first"
                  : "Chat with your students",
              onTap: () {
                if (assignedClass == null || assignedClass!.isEmpty) {
                  Get.snackbar(
                    "Class Not Assigned",
                    "Please assign a class first!",
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                  return;
                }
                // Navigate to GlobalChatScreen with classId
                Get.to(() => GlobalChatScreen(classId: assignedClass!));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
