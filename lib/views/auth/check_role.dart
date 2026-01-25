import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/services/firebase_auth_service.dart';

class CheckRole extends StatefulWidget {
  const CheckRole({super.key});

  @override
  State<CheckRole> createState() => _CheckRoleState();
}

class _CheckRoleState extends State<CheckRole> {
  @override
  void initState() {
    super.initState();
    // This starts the logic immediately when the screen opens
    _determineNavigation();
  }

  Future<void> _determineNavigation() async {
    FirebaseAuthService service = FirebaseAuthService();

    // 1. Brief pause to allow Firebase to finalize the login session
    await Future.delayed(const Duration(milliseconds: 600));

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // 2. Fetch the user document from Firestore
        Map<String, dynamic>? data = await service.getUserRole(user.uid);

        if (data != null) {
          String role = (data['role'] ?? '').toString();

          // 3. Navigate automatically based on role
          if (role == "admin") {
            Get.offAllNamed('/adminDashboard');
          } else if (role == "teacher") {
            Get.offAllNamed('/teacherDashboard');
          } else if (role == "student") {
            Get.offAllNamed('/studentDashboard');
          } else {
            _handleError("Role not found. Contact Admin.");
          }
        } else {
          _handleError("User data not found in database.");
        }
      } catch (e) {
        _handleError("Error: $e");
      }
    } else {
      // If no user found, go back to Login
      Get.offAllNamed('/login');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Syncing Dashboard...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
