import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  // --- Professional Contact Info Dialog ---
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
        title: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Get in Touch",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Our team is here to help you with any queries regarding CampusEase.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 25),
            _buildProfessionalContactTile(
              Icons.alternate_email_rounded,
              "Email Support",
              "campusease.support@gmail.com",
            ),
            const SizedBox(height: 16),
            _buildProfessionalContactTile(
              Icons.phone_in_talk_rounded,
              "Direct Helpline",
              "+91 91887 85203",
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Dismiss",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- In-App 5-Star Rating Dialog ---
  void _showRatingDialog(BuildContext context) {
    int selectedStars = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            "Rate CampusEase",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "How is your experience so far?",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedStars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: index < selectedStars
                          ? Colors.amber
                          : Colors.white24,
                      size: 36,
                    ),
                    onPressed: () => setState(() => selectedStars = index + 1),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Later",
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thank you for your feedback!")),
                );
              },
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalContactTile(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "About Us",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Center(
            child: Column(
              children: [
                _buildGlowLogo(),
                const SizedBox(height: 20),
                const Text(
                  "CampusEase",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  "Smart Campus Ecosystem",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildSectionHeader("The Vision"),
          const SizedBox(height: 12),
          _buildGlassCard(
            child: const Text(
              "CampusEase is designed to bridge the gap between students and faculty. We provide an all-in-one ecosystem for attendance, marks, and seamless communication to enhance the academic experience.",
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 36),
          _buildSectionHeader("Built With"),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTechChip("Flutter"),
              _buildTechChip("Firebase"),
              _buildTechChip("Dart"),
              _buildTechChip("GetX"),
              _buildTechChip("Xcode"),
            ],
          ),
          const SizedBox(height: 36),
          _buildSectionHeader("Development Team"),
          const SizedBox(height: 15),
          const DeveloperListTile(
            name: "BINOY P R",
            role: "Project Lead",
            imagePath: "assets/images/background.jpeg",
            profileUrl: "https://instagram.com/_bi.n.oy_",
          ),
          const DeveloperListTile(
            name: "ATHIRA V C",
            role: "Backend Engineer",
            imagePath: "assets/images/background.jpeg",
            profileUrl: "https://instagram.com/__athi___a",
          ),
          const DeveloperListTile(
            name: "ARDRA DAS",
            role: "UI / UX Designer",
            imagePath: "assets/images/background.jpeg",
            profileUrl: "https://instagram.com/ardra",
          ),
          const DeveloperListTile(
            name: "SHYAMRAJ P R",
            role: "Flutter Developer",
            imagePath: "assets/images/background.jpeg",
            profileUrl: "https://instagram.com/shyamraj.p.r",
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showContactDialog(context),
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text("Contact Us"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(context),
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text("Rate App"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                const Divider(color: Colors.white10, thickness: 1),
                const SizedBox(height: 16),
                Text(
                  "Version 1.2.2",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                Text(
                  "© 2026 CampusEase ",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 30),
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
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const CircleAvatar(
        radius: 55,
        backgroundColor: Colors.white10,
        child: CircleAvatar(
          radius: 52,
          backgroundImage: AssetImage("assets/images/background.jpeg"),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.blueAccent,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Colors.white10, thickness: 1)),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

class DeveloperListTile extends StatelessWidget {
  final String name, role, imagePath, profileUrl;
  const DeveloperListTile({
    super.key,
    required this.name,
    required this.role,
    required this.imagePath,
    required this.profileUrl,
  });

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(profileUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $profileUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _launchUrl,
            icon: const Icon(Icons.link, color: Colors.white24, size: 20),
          ),
        ],
      ),
    );
  }
}
