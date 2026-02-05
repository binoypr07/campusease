import 'package:campusease/views/aboutus/about_us_page.dart';
import 'package:campusease/views/chat/global_chat_screen.dart';
import 'package:campusease/views/feepayment/fee_payment_page.dart';
import 'package:campusease/views/ai/library_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'editable_timetable_page.dart';
import 'teacher_feedback_page.dart';
import 'poll/teacherPollPage.dart';
import 'poll/teacher_poll_results.dart' as pollResults;
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

  // ---------------- NEW SERVICE CARD  ----------------
  Widget buildServiceButton({
    required IconData icon,
    required String title,
    String? url, 
    VoidCallback? onTap, 
  }) {
    return Expanded(
      child: GestureDetector(
        onTap:
            onTap ??
            () async {
              if (url != null && url.isNotEmpty) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.blueAccent, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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

      // --- GLOW CHAT BUTTON ---
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
            // ---------------- SERVICES SECTION ----------------
            // ---------------- ONLINE  ----------------
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 16, top: 20),
              child: Text(
                "Online Services",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildServiceButton(
                  icon: Icons.account_balance_wallet,
                  title: "Fees",
                  url: "", 
                  onTap: () => Get.to(
                    () => FeePaymentPage(studentName: '', studentId: ''),
                  ),
                ),
                buildServiceButton(
                  icon: Icons.language,
                  title: "Web",
                  url: "https://uoc.ac.in/",
                ),
                buildServiceButton(
                  icon: Icons.menu_book,
                  title: "Notes",
                  url: "https://sde.uoc.ac.in/?q=content/study-material",
                ),
                buildServiceButton(
                  icon: Icons.campaign_sharp,
                  title: "Result",
                  url: "https://results.uoc.ac.in/",
                ),
              ],
            ),
            const SizedBox(height: 100),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
