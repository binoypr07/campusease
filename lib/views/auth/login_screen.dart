import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/firebase_auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  FirebaseAuthService authService = FirebaseAuthService();

  bool isLoading = false;
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---------------------------- APP TITLE ----------------------------
              Text(
                "CampusEase",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                "Login to Continue",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),

              const SizedBox(height: 45),

              // ---------------------------- EMAIL ----------------------------
              TextField(
                controller: email,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 20),

              // ---------------------------- PASSWORD ----------------------------
              TextField(
                controller: password,
                obscureText: !showPassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),
              // ---------------------------- FORGOT PASSWORD ----------------------------
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    String userEmail = email.text.trim();

                    if (userEmail.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Email Required"),
                          content: const Text("Please enter your email first."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // Popup to confirm email
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: const Text(
                            "Reset Password",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            "A reset link will be sent to:\n\n$userEmail",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);

                                try {
                                  // SEND FIREBASE RESET MAIL
                                  await FirebaseAuth.instance
                                      .sendPasswordResetEmail(email: userEmail);

                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Email Sent"),
                                      content: const Text(
                                        "A password reset link has been sent to your email.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                } catch (e) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Error"),
                                      content: Text(
                                        "Failed to send reset link:\n$e",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                "Send Link",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 5, 5, 5),
                          Color.fromARGB(255, 8, 8, 8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 247, 129, 129),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // ---------------------------- LOGIN BUTTON ----------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // ---------------------------- REGISTER OPTIONS ----------------------------
              TextButton(
                onPressed: () => Get.toNamed('/registerStudent'),
                child: const Text(
                  "Register as Student",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              TextButton(
                onPressed: () => Get.toNamed('/registerTeacher'),
                child: const Text(
                  "Register as Teacher",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------- LOGIN FUNCTION ----------------------------
  Future<void> loginUser() async {
    setState(() => isLoading = true);

    var user = await authService.login(email.text.trim(), password.text.trim());

    setState(() => isLoading = false);

    if (user != null) {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"fcmToken": token});
      }
      Get.offAllNamed('/checkRole');
    } else {
      Get.snackbar(
        "Login Failed",
        "Invalid credentials or account not approved",
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
    }
  }
}
