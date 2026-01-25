import 'package:campusease/views/student/global_chat_screen.dart';
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
      curve: Curves.elasticOut, // This gives it the "Pop" effect
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

                    // Logic: If post is newer than 24 hours, show animated dot
                    if (DateTime.now().difference(lastTime).inHours < 24) {
                      showRedDot = true;
                      _notifController.forward(); // Start Pop Animation
                    } else {
                      _notifController.reverse(); // Hide Dot
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
                // ------------------ CLASS CHAT ------------------
                buildCard(
                  icon: Icons.chat_bubble_outline,
                  title: "Class Chat",
                  subtitle: assignedClass == null || assignedClass!.isEmpty
                      ? "Assign class first"
                      : "Chat with your class",
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
      },
    );
  }
}
