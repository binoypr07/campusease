import 'package:campusease/views/aboutus/about_us_page.dart';
import 'package:campusease/views/chat/global_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr.dart';
import 'timetable_page.dart';
import 'feedback_page.dart';
import 'polls_page.dart';
import 'student_internal_marks.dart';
import 'library_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  // Animation variables
  late AnimationController _notifController;
  late Animation<double> _notifAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the bouncy animation
    _notifController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _notifAnimation = CurvedAnimation(
      parent: _notifController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _notifController.dispose();
    super.dispose();
  }

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
        final assignedClass = data['classYear'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text("Student Dashboard"),
            centerTitle: true,
            // ABOUT US ICON (LEFT)
            leading: IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: "About Us",
              onPressed: () => Get.to(() => const AboutUsPage()),
            ),
            actions: [
              // AI Assistant
              IconButton(
                iconSize: 28,
                tooltip: "Smart AI Assist",
                icon: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purpleAccent,
                ),
                onPressed: () => Get.to(() => const LibraryPage()),
              ),

              // REAL-TIME ANIMATED ANNOUNCEMENTS
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('announcements')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, notifSnapshot) {
                  bool showRedDot = false;

                  if (notifSnapshot.hasData &&
                      notifSnapshot.data!.docs.isNotEmpty) {
                    DateTime lastTime =
                        (notifSnapshot.data!.docs.first['timestamp']
                                as Timestamp)
                            .toDate();

                    if (DateTime.now().difference(lastTime).inHours < 24) {
                      showRedDot = true;
                      _notifController.forward();
                    } else {
                      _notifController.reverse();
                    }
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        iconSize: 28,
                        icon: Icon(
                          showRedDot
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                        ),
                        tooltip: 'Announcements',
                        onPressed: () => Get.toNamed('/studentAnnouncements'),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: ScaleTransition(
                          scale: _notifAnimation,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Profile Icon
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.person_outline),
                tooltip: 'My Profile',
                onPressed: () => Get.toNamed('/studentProfile'),
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
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () {
                if (assignedClass.isEmpty) {
                  Get.snackbar(
                    "Error",
                    "Class not assigned",
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                  return;
                }
                Get.to(() => GlobalChatScreen(classId: assignedClass));
              },
            ),
          ),

          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const SizedBox(height: 10),
                buildCard(
                  icon: Icons.calendar_month,
                  title: "Attendance",
                  subtitle: "View your attendance",
                  onTap: () => Get.toNamed('/studentAttendance'),
                ),
                buildCard(
                  icon: Icons.grade,
                  title: "Internal Marks",
                  subtitle: "View your marks",
                  onTap: () {
                    if (assignedClass.isEmpty) {
                      Get.snackbar(
                        "Error",
                        "Class not assigned",
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
                buildCard(
                  icon: Icons.schedule,
                  title: "Time Table",
                  subtitle: "View your daily schedule",
                  onTap: () {
                    if (assignedClass.isEmpty) {
                      Get.snackbar(
                        "Error",
                        "Class not assigned",
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
                buildCard(
                  icon: Icons.poll,
                  title: "Polls",
                  subtitle: "Participate in active polls",
                  onTap: () => Get.to(
                    () => PollsPage(
                      studentId: studentId,
                      classYear: studentClass,
                    ),
                  ),
                ),
                buildCard(
                  icon: Icons.feedback,
                  title: "Feedback",
                  subtitle: "Send feedback to teachers/admin",
                  onTap: () => Get.to(
                    () => FeedbackPage(
                      studentId: studentId,
                      studentName: studentName,
                      classYear: studentClass,
                    ),
                  ),
                ),
                // Extra space at bottom so FAB doesn't cover the last card
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}
