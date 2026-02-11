import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class TeacherFeeSetupPage extends StatefulWidget {
  final String assignedClass;

  const TeacherFeeSetupPage({super.key, required this.assignedClass});

  @override
  State<TeacherFeeSetupPage> createState() => _TeacherFeeSetupPageState();
}

class _TeacherFeeSetupPageState extends State<TeacherFeeSetupPage> {
  final TextEditingController _amountController = TextEditingController();
  bool isSaving = false;

  Future<void> _saveFee() async {
    String amountText = _amountController.text.trim();

    // Guard 1: Empty Text
    if (amountText.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter an amount",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Guard 2: Empty assignedClass (Prevents Firestore path crash)
    if (widget.assignedClass.isEmpty) {
      Get.snackbar(
        "Error",
        "No class assigned to your profile",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Safe parsing
      double amount = double.parse(amountText);

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('fee_settings')
          .doc(widget.assignedClass) // Document ID will be 'CS3'
          .set({
            'amount': amount,
            'className': widget.assignedClass,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      Get.snackbar(
        "Success",
        "Fee updated for ${widget.assignedClass}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Return to Dashboard after a second
      Future.delayed(const Duration(seconds: 1), () => Get.back());
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Manage Class Fees"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SET FEE FOR",
              style: TextStyle(color: Colors.white70, letterSpacing: 1.2),
            ),
            const SizedBox(height: 5),
            Text(
              widget.assignedClass,
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: "Amount (₹)",
                labelStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(
                  Icons.currency_rupee,
                  color: Colors.blueAccent,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isSaving ? null : _saveFee,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Update Fee",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
