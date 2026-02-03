import 'package:flutter/foundation.dart';
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
  late Animation<double> _smoothAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _smoothAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  /// TITLE — PROFESSIONAL SILKY GRADIENT FLOW
  Widget staggeredText(String text, double fontSize) {
    return AnimatedBuilder(
      animation: _smoothAnimation,
      builder: (context, child) {
        final double t = _smoothAnimation.value;

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(6.0 - (t * 12.0), 0),
              end: Alignment(2.0 - (t * 12.0), 0),
              tileMode: TileMode.repeated,
              colors: const [
                Color(0xFFB5179E), // Muted Rose
                Color(0xFF4361EE), // Deep Blue
                Color(0xFFB5179E),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.white,
              shadows: const [
                Shadow(
                  blurRadius: 8,
                  color: Colors.black54,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
              staggeredText("CampusEase", 40),
              const SizedBox(height: 8),

              AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  double opacityValue =
                      (math.sin(_mainController.value * math.pi * 15) + 1) / 2;
                  return Opacity(
                    opacity: 0.3 + (opacityValue * 0.7),
                    child: const Text(
                      "Login to Continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 191, 225, 229),
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

      if (!kIsWeb) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .update({"fcmToken": token});
        }
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
