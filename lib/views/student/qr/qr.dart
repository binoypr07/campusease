import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class StudentQRPage extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String phone;
  final String department;
  final String classYear;
  final int semester;

  const StudentQRPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.phone,
    required this.department,
    required this.classYear,
    required this.semester,
  });

  @override
  Widget build(BuildContext context) {
    // Convert all student info to JSON string for QR
    final qrData = jsonEncode({
      "name": studentName,
      "admissionNumber": studentId,
      "phone": phone,
      "department": department,
      "class": classYear,
      "semester": semester,
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Student QR Code")),
      body: Center(
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 250,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
