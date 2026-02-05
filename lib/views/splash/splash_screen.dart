import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation; // NEW: For the breathing effect

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true); // NEW: Makes the glow "breathe"

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startNavigation();
  }

  void _startNavigation() async {
    await Future.delayed(const Duration(seconds: 3));

    FirebaseAuth.instance.authStateChanges().first.then((user) {
      if (!mounted) return;

      if (user == null) {
        Get.offAllNamed('/login');
      } else {
        Get.offAllNamed('/checkRole');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND GLOW
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Positioned(
                top: -50,
                left: -50,
                child: Container(
                  height: 350,
                  width: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(
                          _glowAnimation.value * 0.3,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 2. LOGO WITH ENHANCED SHADOW
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildGlowLogo(),
                  ),
                ),

                const SizedBox(height: 40),

                // 3. TEXT WITH INDIVIDUAL DELAYS
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        "CampusEase",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // SHIMMER TAGLINE EFFECT
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Text(
                            "Smart Campus Ecosystem",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueAccent.withOpacity(
                                _glowAnimation.value + 0.4,
                              ),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // 4. CLEANER PROGRESS BAR
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blueAccent,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowLogo() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.15),
            blurRadius: 50,
            spreadRadius: 15,
          ),
        ],
      ),
      child: const CircleAvatar(
        radius: 65,
        backgroundColor: Colors.white10,
        child: CircleAvatar(
          radius: 62,
          backgroundImage: AssetImage("assets/images/background.jpeg"),
        ),
      ),
    );
  }
}
