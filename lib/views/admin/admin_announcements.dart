import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final TextEditingController titleC = TextEditingController();
  final TextEditingController msgC = TextEditingController();

  String audienceType = "all";
  String? selectedDept;
  String? selectedClass;

  final List<String> departments = [
    "Computer Science", "Physics", "Chemistry", "Maths",
    "Malayalam", "Hindi", "English", "History",
    "Economics", "Commerce", "Zoology", "Botany"
  ];

  final List<String> classes = [
    "CS1","CS2","PHY1","PHY2","MAT1","MAT2",
    "CHE1","CHE2","ZOO1","ZOO2","ENG1","ENG2"
  ];

  Future<void> postAnnouncement() async {
    if (titleC.text.trim().isEmpty || msgC.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection("announcements").add({
      "title": titleC.text.trim(),
      "message": msgC.text.trim(),
      "createdAt": DateTime.now(),
      "createdBy": FirebaseAuth.instance.currentUser!.uid,
      "audienceType": audienceType,
      "targetDept": selectedDept,
      "targetClass": selectedClass,
    });

    titleC.clear();
    msgC.clear();
    selectedDept = null;
    selectedClass = null;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Announcement Posted"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------------- CREATE ANNOUNCEMENT ----------------
            TextField(
              controller: titleC,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgC,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Message"),
            ),
            const SizedBox(height: 12),

            // AUDIENCE CHOOSER
            DropdownButtonFormField<String>(
              value: audienceType,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Send To"),
              items: const [
                DropdownMenuItem(value: "all", child: Text("All Users")),
                DropdownMenuItem(value: "students", child: Text("Only Students")),
                DropdownMenuItem(value: "teachers", child: Text("Only Teachers")),
                DropdownMenuItem(value: "department", child: Text("Specific Department")),
                DropdownMenuItem(value: "class", child: Text("Specific Class")),
              ],
              onChanged: (v) {
                setState(() {
                  audienceType = v!;
                  selectedDept = null;
                  selectedClass = null;
                });
              },
            ),

            if (audienceType == "department")
              DropdownButtonFormField<String>(
                value: selectedDept,
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Select Department"),
                items: departments.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e))
                ).toList(),
                onChanged: (v) => setState(() => selectedDept = v),
              ),

            if (audienceType == "class")
              DropdownButtonFormField<String>(
                value: selectedClass,
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Select Class"),
                items: classes.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e))
                ).toList(),
                onChanged: (v) => setState(() => selectedClass = v),
              ),

            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: postAnnouncement,
              child: const Text("POST ANNOUNCEMENT"),
            ),

            const Divider(height: 30, color: Colors.white),

            // ---------------- VIEW ANNOUNCEMENTS ----------------
            const Text(
              "Previous Announcements",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("announcements")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text("No announcements yet"));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var a = docs[index];
                      return Card(
                        child: ListTile(
                          title: Text(a["title"], style: const TextStyle(color: Colors.white)),
                          subtitle: Text(a["message"], style: const TextStyle(color: Colors.white70)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
