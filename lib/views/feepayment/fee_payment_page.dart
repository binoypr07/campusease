import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_success_page.dart';

class FeePaymentPage extends StatelessWidget {
  final String studentName;
  final String studentId;

  FeePaymentPage({
    super.key,
    required this.studentName,
    required this.studentId,
  });

  // --- THE REAL REDIRECT LOGIC ---
  Future<void> _initiateRealPayment(String appName) async {
    // 1. SET YOUR DETAILS HERE
    const String receiverUpiId =
        "yourname@upi"; // <--- CHANGE THIS TO YOUR UPI ID
    const String receiverName = "CampusEase Admin";
    const String amount = "5500.00";
    const String transactionNote = "University Fee Payment";

    // 2. CONSTRUCT THE UPI URI
    // This is the standard protocol that opens GPay, PhonePe, etc.
    final String upiUrl =
        'upi://pay?pa=$receiverUpiId&pn=$receiverName&am=$amount&cu=INR&tn=$transactionNote';

    final Uri uri = Uri.parse(upiUrl);

    try {
      // 3. ATTEMPT TO LAUNCH THE EXTERNAL APP
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode
              .externalApplication, // This leaves your app and opens the bank app
        );

        // 4. NAVIGATION AFTER RETURN
        // When the user switches back to your app, we show the success screen
        Get.to(() => PaymentSuccessPage(methodName: appName));
      } else {
        Get.snackbar(
          "No UPI App Found",
          "Please install Google Pay, PhonePe, or Paytm to continue.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint("Payment Error: $e");
      Get.snackbar("Error", "Could not open $appName");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Final Checkout", style: TextStyle(fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildAmountCard(),
              const SizedBox(height: 35),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "SELECT PAYMENT APP",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // UPI GRID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildUpiOption(
                    "Google Pay",
                    Icons.g_mobiledata_rounded,
                    Colors.blue,
                  ),
                  _buildUpiOption("PhonePe", Icons.vibration, Colors.purple),
                  _buildUpiOption(
                    "Paytm",
                    Icons.account_balance_wallet,
                    Colors.lightBlue,
                  ),
                  _buildUpiOption("Any UPI", Icons.qr_code_2, Colors.green),
                ],
              ),

              const SizedBox(height: 30),
              _buildListTile(Icons.credit_card, "Credit / Debit Cards"),
              _buildListTile(Icons.account_balance, "Net Banking"),

              const SizedBox(height: 50),
              const Text(
                "🔒 This transaction is secured via UPI Protocol",
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Text("Amount to Pay", style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 10),
          const Text(
            "₹5,500.00",
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Payee: $studentName",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiOption(String name, IconData icon, Color color) {
    return InkWell(
      onTap: () => _initiateRealPayment(name),
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 35),
          ),
          const SizedBox(height: 8),
          Text(
            name.split(' ')[0],
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.05),
        child: Icon(icon, color: Colors.blueAccent, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white24,
        size: 14,
      ),
      onTap: () => _initiateRealPayment(title),
    );
  }
}
