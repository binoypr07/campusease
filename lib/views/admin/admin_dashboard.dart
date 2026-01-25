import 'package:campusease/views/admin/admin_library_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

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
  // UI BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(title: const Text("Admin Dashboard"), centerTitle: true),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // ------------------- PENDING USERS -------------------
            buildCard(
              icon: Icons.pending_actions,
              title: "Pending User Approvals",
              subtitle: "Approve new students & teachers",
              onTap: () => Get.toNamed('/pendingUsers'),
            ),

            // ------------------- ALL TEACHERS -------------------
            buildCard(
              icon: Icons.people,
              title: "All Teachers",
              subtitle: "View teachers department-wise",
              onTap: () => Get.toNamed('/adminTeachers'),
            ),

            //------------all students---------------
            buildCard(
              icon: Icons.school,
              title: "All Students",
              subtitle: "View students by department/class",
              onTap: () => Get.toNamed('/adminStudents'),
            ),

            // ------------------- ATTENDANCE REPORTS -------------------
            buildCard(
              icon: Icons.calendar_month,
              title: "Attendance Reports",
              subtitle: "Daily / Monthly / Semester",
              onTap: () {
                Get.toNamed('/adminAttendance');
              },
            ),

            // ------------------- ANNOUNCEMENTS -------------------
            buildCard(
              icon: Icons.campaign,
              title: "Announcements",
              subtitle: "create & view",
              onTap: () {
                Get.toNamed('/adminAnnouncements');
              },
            ),

            // ------------------- SMART LIBRARY UPLOAD -------------------
            buildCard(
              icon: Icons.library_add,
              title: "Manage Library",
              subtitle: "Upload PDFs & Manage Books",
              onTap: () {
                // We will create this page in Step 2
                Get.to(() => const AdminLibraryPage());
              },
            ),
            const SizedBox(height: 20),

            // ------------------- LOGOUT -------------------
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 227, 226, 226),
                foregroundColor: const Color.fromARGB(255, 12, 11, 11),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              onPressed: () {
                Get.defaultDialog(
                  title: "Confirm Logout",
                  middleText: "Are you sure you want to logout?",
                  radius: 14,
                  textCancel: "Cancel",
                  textConfirm: "Logout",
                  cancelTextColor: const Color.fromARGB(255, 242, 238, 238),
                  confirmTextColor: Colors.white,
                  buttonColor: const Color.fromARGB(255, 211, 27, 27),
                  onConfirm: () {
                    Get.offAllNamed('/login');
                  },
                );
              },
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
