import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  State<AdminAnnouncementScreen> createState() =>
      _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  TextEditingController titleC = TextEditingController();
  TextEditingController messageC = TextEditingController();

  String targetRole = "all";
  String? selectedClass;
  String? selectedDept;

  final List<String> departments = [
    "Computer Science",
    "Physics",
    "Chemistry",
    "Maths",
    "Malayalam",
    "Hindi",
    "English",
    "History",
    "Economics",
    "Commerce",
    "Zoology",
    "Botany"
  ];

  final List<String> classList = [
    "CS1", "CS2", "CS3",
    "PHY1", "PHY2", "PHY3",
    "CHE1", "CHE2", "CHE3",
    "ENG1", "ENG2", "ENG3",
    "MAT1", "MAT2", "MAT3",
    "ZOO1", "ZOO2", "ZOO3",
    "BOO1", "BOO2", "BOO3",
  ];

  Future<void> _createAnnouncement({String? editId}) async {
    if (titleC.text.isEmpty || messageC.text.isEmpty) {
      Get.snackbar("Error", "Please fill all fields",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final data = {
      "title": titleC.text.trim(),
      "message": messageC.text.trim(),
      "roleTarget": targetRole,
      "classTarget": selectedClass ?? "",
      "departmentTarget": selectedDept ?? "",
      "timestamp": Timestamp.now(),
      "creatorRole": "admin",
    };

    if (editId == null) {
      await FirebaseFirestore.instance.collection("announcements").add(data);
      Get.snackbar("Success", "Announcement Created!",
          backgroundColor: Colors.green, colorText: Colors.black);
    } else {
      await FirebaseFirestore.instance
          .collection("announcements")
          .doc(editId)
          .update(data);

      Get.snackbar("Success", "Announcement Updated!",
          backgroundColor: Colors.green, colorText: Colors.black);
    }

    titleC.clear();
    messageC.clear();
    setState(() {
      targetRole = "all";
      selectedClass = null;
      selectedDept = null;
    });
  }

  void _editDialog(DocumentSnapshot doc) {
    titleC.text = doc["title"];
    messageC.text = doc["message"];
    targetRole = doc["roleTarget"];
    selectedClass = doc["classTarget"];
    selectedDept = doc["departmentTarget"];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _formUI(onSubmit: () => _createAnnouncement(editId: doc.id))
            ],
          ),
        );
      },
    );
  }

  Widget _formUI({required VoidCallback onSubmit}) {
    return Column(
      children: [
        TextField(
          controller: titleC,
          decoration: const InputDecoration(labelText: "Title"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: messageC,
          maxLines: 3,
          decoration: const InputDecoration(labelText: "Message"),
        ),
        const SizedBox(height: 20),

        // ROLE SELECTION
        DropdownButtonFormField<String>(
          value: targetRole,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Send To"),
          items: const [
            DropdownMenuItem(value: "all", child: Text("All Users")),
            DropdownMenuItem(value: "teachers", child: Text("Teachers Only")),
            DropdownMenuItem(value: "students", child: Text("Students Only")),
            DropdownMenuItem(
                value: "specificClass", child: Text("Specific Class")),
            DropdownMenuItem(
                value: "specificDepartment", child: Text("Specific Department")),
          ],
          onChanged: (v) {
            setState(() => targetRole = v!);
          },
        ),

        const SizedBox(height: 12),

        if (targetRole == "specificClass")
          DropdownButtonFormField<String>(
            value: selectedClass,
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: "Choose Class"),
            items: classList
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => selectedClass = v),
          ),

        if (targetRole == "specificDepartment")
          DropdownButtonFormField<String>(
            value: selectedDept,
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: "Choose Department"),
            items: departments
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => selectedDept = v),
          ),

        const SizedBox(height: 20),
        ElevatedButton(onPressed: onSubmit, child: const Text("Save"))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Announcements")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          titleC.clear();
          messageC.clear();
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black,
            builder: (_) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: _formUI(onSubmit: () => _createAnnouncement()),
              );
            },
          );
        },
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("announcements")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              var a = docs[i];

              return Card(
                child: ListTile(
                  title: Text(a["title"],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  subtitle: Text(a["message"],
                      style: const TextStyle(color: Colors.white70)),
                  trailing: PopupMenuButton(
                    color: Colors.black,
                    onSelected: (value) {
                      if (value == "edit") {
                        _editDialog(a);
                      } else if (value == "delete") {
                        FirebaseFirestore.instance
                            .collection("announcements")
                            .doc(a.id)
                            .delete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: "edit", child: Text("Edit")),
                      PopupMenuItem(value: "delete", child: Text("Delete")),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
