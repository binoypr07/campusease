import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_success_page.dart';

class FeePaymentPage extends StatefulWidget {
  final String studentName;
  final String studentId;
  final String classYear; // This MUST match the document ID in fee_settings

  const FeePaymentPage({
    super.key,
    required this.studentName,
    required this.studentId,
    required this.classYear,
  });

  @override
  State<FeePaymentPage> createState() => _FeePaymentPageState();
}

class _FeePaymentPageState extends State<FeePaymentPage> {
  double feeAmount = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFee();
  }

  // --- FETCH DYNAMIC FEE FROM FIRESTORE ---
  Future<void> _fetchFee() async {
    // Debugging: Check the console to see what ID the app is searching for
    debugPrint(
      "DEBUG: Searching fee_settings for Document ID: '${widget.classYear}'",
    );

    if (widget.classYear.isEmpty) {
      setState(() => isLoading = false);
      Get.snackbar("Error", "Class identifier is missing from your profile.");
      return;
    }

    try {
      // .trim() removes any accidental spaces like "CS3 "
      var doc = await FirebaseFirestore.instance
          .collection('fee_settings')
          .doc(widget.classYear.trim())
          .get();

      if (doc.exists) {
        debugPrint("DEBUG: Document found! Data: ${doc.data()}");
        setState(() {
          // Ensure the key 'amount' matches exactly what the teacher saved
          feeAmount = (doc.data()?['amount'] ?? 0.0).toDouble();
          isLoading = false;
        });
      } else {
        debugPrint("DEBUG: No document found with ID: ${widget.classYear}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching fee: $e");
    }
  }

  // --- UPI PAYMENT LOGIC ---
  Future<void> _initiateRealPayment(String appName) async {
    if (feeAmount <= 0) {
      Get.snackbar(
        "Notice",
        "Fee amount is not valid.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    const String receiverUpiId = "yourname@upi"; // <--- UPDATE THIS
    const String receiverName = "CampusEase Admin";

    final String encodedName = Uri.encodeComponent(receiverName);
    final String encodedNote = Uri.encodeComponent(
      "Fee: ${widget.studentName} (${widget.classYear})",
    );
    final String amountStr = feeAmount.toStringAsFixed(2);

    final String upiUrl =
        'upi://pay?pa=$receiverUpiId&pn=$encodedName&am=$amountStr&cu=INR&tn=$encodedNote';

    final Uri uri = Uri.parse(upiUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Inside FeePaymentPage
        Get.to(
          () => PaymentSuccessPage(
            methodName: appName,
            amount: feeAmount.toStringAsFixed(2),
            studentName: widget.studentName,
            classYear: widget.classYear,
          ),
        );
        ;
      } else {
        Get.snackbar("Error", "No UPI app found for $appName");
      }
    } catch (e) {
      Get.snackbar("Error", "Could not open $appName");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          "Final Checkout",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAmountCard(),
                  const SizedBox(height: 35),
                  if (feeAmount > 0) ...[
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildUpiOption(
                          "Google Pay",
                          Icons.g_mobiledata_rounded,
                          Colors.blue,
                        ),
                        _buildUpiOption(
                          "PhonePe",
                          Icons.vibration,
                          Colors.purple,
                        ),
                        _buildUpiOption(
                          "Paytm",
                          Icons.account_balance_wallet,
                          Colors.lightBlue,
                        ),
                        _buildUpiOption(
                          "Any UPI",
                          Icons.qr_code_2,
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildListTile(Icons.credit_card, "Credit / Debit Cards"),
                    _buildListTile(Icons.account_balance, "Net Banking"),
                  ] else
                    _buildEmptyState(),
                  const SizedBox(height: 50),
                  const Text(
                    "🔒 Secured via UPI Protocol",
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
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
          Text(
            "₹${feeAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Payee: ${widget.studentName}\nClass ID: ${widget.classYear}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 30),
          const SizedBox(height: 10),
          Text(
            "Fee details for '${widget.classYear}' not found.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Please ask your teacher to set the fee in the Teacher Dashboard.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiOption(String name, IconData icon, Color color) {
    return InkWell(
      onTap: () => _initiateRealPayment(name),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            name.split(' ')[0],
            style: const TextStyle(color: Colors.white70, fontSize: 11),
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
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white24,
        size: 12,
      ),
      onTap: () => _initiateRealPayment(title),
    );
  }
}
