import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InternalMarksPage extends StatefulWidget {
  final String className;
  const InternalMarksPage({super.key, required this.className});

  @override
  State<InternalMarksPage> createState() => _InternalMarksPageState();
}

class _InternalMarksPageState extends State<InternalMarksPage> {
  List<Map<String, dynamic>> students = [];
  String? selectedStudentId;

  final mid1Controller = TextEditingController();
  final mid2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('classYear', isEqualTo: widget.className)
          .where('role', isEqualTo: 'student')
          .get();

      setState(() {
        students = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return {'id': doc.id, 'name': data['name'] ?? 'No Name'};
        }).toList();
      });
    } catch (e) {
      print("Error fetching students: $e");
    }
  }

  void submitMarks() async {
    if (selectedStudentId == null ||
        mid1Controller.text.isEmpty ||
        mid2Controller.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final mid1 = int.tryParse(mid1Controller.text) ?? 0;
    final mid2 = int.tryParse(mid2Controller.text) ?? 0;

    await FirebaseFirestore.instance
        .collection('internalMarks')
        .doc("${widget.className}_${selectedStudentId!}")
        .set({
          'mid1': mid1,
          'mid2': mid2,
          'total': mid1 + mid2,
          'studentId': selectedStudentId,
          'className': widget.className,
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Marks saved")));

    mid1Controller.clear();
    mid2Controller.clear();
    setState(() {
      selectedStudentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter Internal Marks")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedStudentId,
              hint: const Text("Select Student"),
              items: students
                  .map(
                    (student) => DropdownMenuItem<String>(
                      value: student['id'],
                      child: Text(student['name'] ?? 'No Name'),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedStudentId = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mid1Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Mid1 Marks",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mid2Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Mid2 Marks",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitMarks,
              child: const Text("Submit Marks"),
            ),
          ],
        ),
      ),
    );
  }
}
