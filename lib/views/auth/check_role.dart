import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/services/firebase_auth_service.dart';

class CheckRole extends StatelessWidget {
  const CheckRole({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseAuthService service = FirebaseAuthService();
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<Map<String, dynamic>?>(
      future: service.getUserRole(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("User not approved yet")),
          );
        }

        Map<String, dynamic> data = snapshot.data!;
        String role = (data['role'] ?? '').toString();

        // Safe navigation AFTER build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (role == "admin") {
            Get.offAllNamed('/adminDashboard');
          } else if (role == "teacher") {
            Get.offAllNamed('/teacherDashboard');
          } else {
            Get.offAllNamed('/studentDashboard');
          }
        });

        return const Scaffold(
          body: Center(
            child: Text(
              "Checking role...",
              style: TextStyle(fontSize: 20),
            ),
          ),
        );
      },
    );
  }
}
