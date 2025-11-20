import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/notification_service.dart';





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
              // ----------------------------   FORGOT PASSWORD ----------------------------
              Align(
                alignment: Alignment.centerRight,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 100),
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      String userEmail = email.text
                          .trim(); // <-- your existing email controller

                      if (userEmail.isEmpty) {
                        // If email empty show warning popup
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Email Required"),
                            content: const Text(
                              "Please enter your email before resetting password.",
                            ),
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

                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            backgroundColor: const Color(0xFF121212),
                            child: SizedBox(
                              width: 260,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Reset Password",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 15),

                                    // ---------------- SHOW USER EMAIL ----------------
                                    Text(
                                      "We will send an OTP to:",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      userEmail,
                                      style: const TextStyle(
                                        color: Colors.pinkAccent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 25),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // CANCEL BUTTON
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        // SEND OTP BUTTON
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pinkAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            // TODO: send OTP to userEmail
                                            Navigator.pop(
                                              context,
                                            ); // close previous popup

                                            // Show OTP verification popup
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                TextEditingController
                                                otpController =
                                                    TextEditingController();

                                                return Dialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFF121212,
                                                  ),
                                                  child: SizedBox(
                                                    width: 260,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            20,
                                                          ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                            "Verify OTP",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                            height: 20,
                                                          ),

                                                          // OTP TextField
                                                          TextField(
                                                            controller:
                                                                otpController,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                            decoration: const InputDecoration(
                                                              labelText:
                                                                  "Enter OTP",
                                                              labelStyle:
                                                                  TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                              enabledBorder:
                                                                  UnderlineInputBorder(
                                                                    borderSide:
                                                                        BorderSide(
                                                                          color:
                                                                              Colors.white38,
                                                                        ),
                                                                  ),
                                                              focusedBorder:
                                                                  UnderlineInputBorder(
                                                                    borderSide:
                                                                        BorderSide(
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                  ),
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                            height: 25,
                                                          ),

                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              // CANCEL
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                                child: const Text(
                                                                  "Cancel",
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .redAccent,
                                                                  ),
                                                                ),
                                                              ),

                                                              const SizedBox(
                                                                width: 10,
                                                              ),

                                                              // VERIFY OTP BUTTON
                                                              ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .pinkAccent,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                ),
                                                                onPressed: () {
                                                                  String otp =
                                                                      otpController
                                                                          .text
                                                                          .trim();

                                                                  // TODO: verify OTP logic here

                                                                  Navigator.pop(
                                                                    context,
                                                                  );
                                                                },
                                                                child: const Text(
                                                                  "Verify OTP",
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          child: const Text("Send OTP"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              218,
                              216,
                              220,
                            ).withOpacity(0.0),
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
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
       // get & store token
        String? token = await NotificationService.getToken();
        if (token != null) {
         await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
        });
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
