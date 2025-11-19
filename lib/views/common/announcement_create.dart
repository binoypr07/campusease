import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AnnouncementCreateScreen extends StatefulWidget {
  const AnnouncementCreateScreen({super.key});

  @override
  State<AnnouncementCreateScreen> createState() =>
      _AnnouncementCreateScreenState();
}

class _AnnouncementCreateScreenState extends State<AnnouncementCreateScreen> {
  final TextEditingController title = TextEditingController();
  final TextEditingController message = TextEditingController();

  String target = "ALL";
  final List<String> classes = [
    "ALL",
    "CS1","CS2","CS3",
    "PHY1","PHY2","PHY3",
    "CHE1","CHE2","CHE3",
    "IC1","IC2","IC3",
    "MAT1","MAT2","MAT3",
    "ZOO1","ZOO2","ZOO3",
    "BOO1","BOO2","BOO3",
    "BCOM1","BCOM2","BCOM3",
    "ECO1","ECO2","ECO3",
    "HIN1","HIN2","HIN3",
    "HIS1","HIS2","HIS3",
    "ENG1","ENG2","ENG3",
    "MAL1","MAL2","MAL3",
  ];

  bool loading = false;

  Future<void> publishAnnouncement() async {
    if (title.text.trim().isEmpty || message.text.trim().isEmpty) {
      Get.snackbar("Missing", "Enter all fields",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("announcements").add({
      "title": title.text.trim(),
      "message": message.text.trim(),
      "target": target,
      "timestamp": DateTime.now(),
    });

    setState(() => loading = false);

    Get.snackbar("Success", "Announcement Published!",
        backgroundColor: Colors.black, colorText: Colors.white);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Announcement")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: message,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Message"),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: target,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              items: classes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => target = v!),
              decoration: const InputDecoration(labelText: "Send To"),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : publishAnnouncement,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Publish"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
