import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/firebase_auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  FirebaseAuthService authService = FirebaseAuthService();

  bool isLoading = false;
  bool showPassword = false;

  late AnimationController _mainController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // animation controller still needed for text wave
  }

  @override
  void dispose() {
    _mainController.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  /// TITLE ANIMATION (UNCHANGED)
  Widget staggeredText(String text, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').asMap().entries.map((entry) {
        int index = entry.key;
        String char = entry.value;

        return AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            double waveValue = 0.0;
            if (_mainController.isAnimating) {
              waveValue = Curves.easeInOut.transform(
                ((_mainController.value - (index * 0.08)) % 1.0).clamp(
                  0.0,
                  1.0,
                ),
              );
            }
            double yOffset =
                Curves.easeInOut.transform(
                  (0.5 - (0.5 - waveValue).abs()) * 2,
                ) *
                -12;

            Color dynamicColor = HSVColor.fromAHSV(
              1.0,
              (_mainController.value * 360 + (index * 20)) % 360,
              0.4,
              0.9,
            ).toColor();

            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Text(
                char,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: dynamicColor,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: dynamicColor.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // static black background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              staggeredText("CampusEase", 40),
              const SizedBox(height: 8),

              AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  double opacityValue =
                      (math.sin(_mainController.value * math.pi * 5) + 1) / 2;
                  return Opacity(
                    opacity: 0.3 + (opacityValue * 0.7),
                    child: const Text(
                      "Login to Continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 45),

              TextField(
                controller: email,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 20),

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

              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () async {
                    String userEmail = email.text.trim();
                    if (userEmail.isEmpty) {
                      _showErrorDialog("Email Required", "Enter email.");
                      return;
                    }
                    _showResetDialog(userEmail);
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Color.fromARGB(255, 247, 129, 129),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () async => loginUser(),
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(String userEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Text("Send link to $userEmail?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.sendPasswordResetEmail(
                email: userEmail,
              );
              Get.snackbar("Success", "Reset link sent!");
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> loginUser() async {
    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      Get.snackbar(
        "Missing Fields",
        "Enter email and password",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      final user = await authService.login(
        email.text.trim(),
        password.text.trim(),
      );
      if (user == null) {
        Get.snackbar(
          "Login Failed",
          "Invalid credentials",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"fcmToken": token});
      }

      Get.offAllNamed('/checkRole');
    } catch (e) {
      Get.snackbar(
        "Login Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
