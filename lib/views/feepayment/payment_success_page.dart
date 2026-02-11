import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String methodName;
  final String amount;
  final String studentName;
  final String classYear;

  const PaymentSuccessPage({
    super.key,
    required this.methodName,
    required this.amount,
    required this.studentName,
    required this.classYear,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Matches FeePaymentPage
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Animated Success Icon with Glow
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 100,
                  ),
                ),
                const SizedBox(height: 25),

                const Text(
                  "Payment Successful",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Transaction has been processed safely",
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),

                const SizedBox(height: 40),

                // 2. Professional Digital Receipt (Dark Theme)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A), // Dark card color
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow(
                        "Amount Paid",
                        "₹$amount",
                        isPrimary: true,
                      ),
                      const SizedBox(height: 15),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 15),
                      _buildReceiptRow("Student Name", studentName),
                      _buildReceiptRow("Class Year", classYear),
                      _buildReceiptRow("Payment Method", methodName),
                      _buildReceiptRow(
                        "Transaction ID",
                        "TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
                      ),
                      const SizedBox(height: 15),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 15),
                      _buildReceiptRow("Status", "COMPLETED", isStatus: true),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // 3. Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // Matches Dashboard
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Get.offAllNamed('/studentDashboard'),
                    child: const Text(
                      "RETURN TO DASHBOARD",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextButton.icon(
                  onPressed: () {
                    Get.snackbar(
                      "Success",
                      "Receipt saved to downloads",
                      backgroundColor: Colors.white10,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(
                    Icons.download_done_rounded,
                    color: Colors.blueAccent,
                  ),
                  label: const Text(
                    "Download E-Receipt",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isStatus = false,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isPrimary ? 20 : 14,
              color: isStatus
                  ? Colors.greenAccent
                  : (isPrimary ? Colors.white : Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
