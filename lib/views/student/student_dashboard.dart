import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
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
              subtitle: "Daily / Monthly / Semester view",
              onTap: () {
                Get.snackbar(
                  "Coming Soon",
                  "Attendance viewing is coming!",
                  backgroundColor: Colors.black,
                  colorText: Colors.white,
                );
              },
            ),

            // ------------------ INTERNAL MARKS ------------------
            buildCard(
              icon: Icons.grade,
              title: "Internal Marks",
              subtitle: "Subject-wise semester marks",
              onTap: () {
                Get.snackbar(
                  "Coming Soon",
                  "Internal marks coming!",
                  backgroundColor: Colors.black,
                  colorText: Colors.white,
                );
              },
            ),

            // ------------------ ANNOUNCEMENTS ------------------
            buildCard(
              icon: Icons.notifications,
              title: "Announcements",
              subtitle: "Notices from teachers & admin",
              onTap: () {
                Get.snackbar(
                  "Coming Soon",
                  "Announcements coming soon!",
                  backgroundColor: Colors.black,
                  colorText: Colors.white,
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
  }
}
