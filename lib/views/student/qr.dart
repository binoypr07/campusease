import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  String scannedData = "Scan a QR code";

  Future<void> scanQRCode() async {
    String result = await FlutterBarcodeScanner.scanBarcode(
      "#ff6666",
      "Cancel",
      true,
      ScanMode.QR,
    );

    if (result != "-1") {
      setState(() {
        scannedData = result;
      });

      // Navigate to student info page with scanned ID
      Get.toNamed('/studentInfo', arguments: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart QR Scanner")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(scannedData, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: scanQRCode, child: const Text("Scan QR")),
          ],
        ),
      ),
    );
  }
}
