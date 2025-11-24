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
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
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
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),

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
              subtitle: "Daily / Monthly / Semester (coming soon)",
              onTap: () {
                Get.snackbar(
                  "Info",
                  "Feature coming soon!",
                  backgroundColor: Colors.black,
                  colorText: Colors.white,
                );
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

            const SizedBox(height: 20),

            // ------------------- LOGOUT -------------------
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
  }
}
