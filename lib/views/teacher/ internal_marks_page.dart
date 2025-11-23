import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InternalMarksPage extends StatefulWidget {
  final String className;
  const InternalMarksPage({super.key, required this.className});

  @override
  State<InternalMarksPage> createState() => _InternalMarksPageState();
}

class _InternalMarksPageState extends State<InternalMarksPage> {
  final studentController = TextEditingController();
  List<Map<String, dynamic>> subjects = [];
  final subjectController = TextEditingController();
  final markController = TextEditingController();

  void addSubject() {
    if (subjectController.text.isEmpty || markController.text.isEmpty) return;

    setState(() {
      subjects.add({
        "name": subjectController.text.trim(),
        "mark": int.tryParse(markController.text.trim()) ?? 0,
      });
    });

    subjectController.clear();
    markController.clear();
  }

  void submitMarks() async {
    if (studentController.text.isEmpty || subjects.isEmpty) return;

    String studentId = studentController.text.trim();

    await FirebaseFirestore.instance
        .collection("internal_marks")
        .doc("${widget.className}_marks")
        .collection("students")
        .doc(studentId)
        .set({"subjects": subjects});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Marks saved")));

    studentController.clear();
    setState(() {
      subjects = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Internal Marks")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: studentController,
              decoration: const InputDecoration(
                labelText: "Student ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Subjects & Marks",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...subjects.map(
              (s) => ListTile(
                title: Text(s["name"]),
                trailing: Text(s["mark"].toString()),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: "Subject",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: markController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Mark",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: addSubject,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: submitMarks, child: const Text("Submit")),
          ],
        ),
      ),
    );
  }
}
