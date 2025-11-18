import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentQRPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentQRPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student QR Code")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              studentName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: studentId, // QR encodes the student's admission number
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
