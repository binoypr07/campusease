import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String methodName;
  final String amount;

  // We use a stateless widget now because the payment happened externally
  PaymentSuccessPage({
    super.key,
    required this.methodName,
    this.amount = "5,500.00",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Success Icon
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF1B5E20),
                  size: 100,
                ),
                const SizedBox(height: 20),

                const Text(
                  "Payment Successful",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your transaction has been completed",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),

                const SizedBox(height: 40),

                // Digital Receipt Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7F9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow("Amount Paid", "₹$amount"),
                      const Divider(height: 30),
                      _buildReceiptRow("Payment Method", methodName),
                      const Divider(height: 30),
                      _buildReceiptRow(
                        "Transaction ID",
                        "CE${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}",
                      ),
                      const Divider(height: 30),
                      _buildReceiptRow("Status", "SUCCESS", isStatus: true),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Return Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Get.offAllNamed('/studentDashboard'),
                  child: const Text(
                    "BACK TO DASHBOARD",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Secondary Action
                TextButton.icon(
                  onPressed: () {
                    Get.snackbar("Downloading", "Receipt saved to gallery");
                  },
                  icon: const Icon(
                    Icons.download,
                    size: 18,
                    color: Colors.blueAccent,
                  ),
                  label: const Text(
                    "Download Receipt",
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isStatus ? const Color(0xFF2E7D32) : Colors.black,
          ),
        ),
      ],
    );
  }
}
