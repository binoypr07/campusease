import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class TeacherPollPage extends StatefulWidget {
  const TeacherPollPage({super.key});

  @override
  State<TeacherPollPage> createState() => _TeacherPollPageState();
}

class _TeacherPollPageState extends State<TeacherPollPage> {
  final questionController = TextEditingController();
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  DateTime? startTime;
  DateTime? endTime;
  String? selectedClass;

  void createPoll() async {
    if (questionController.text.isEmpty ||
        optionControllers.any((c) => c.text.isEmpty) ||
        startTime == null ||
        endTime == null ||
        selectedClass == null)
      return;

    await FirebaseFirestore.instance.collection('polls').add({
      'question': questionController.text,
      'options': optionControllers.map((c) => c.text).toList(),
      'classYear': selectedClass,
      'startTime': startTime,
      'endTime': endTime,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Poll created")));
    questionController.clear();
    optionControllers.forEach((c) => c.clear());
    setState(() {
      startTime = null;
      endTime = null;
      selectedClass = null;
    });
  }

  Future pickDateTime(bool isStart) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        startTime = dateTime;
      } else {
        endTime = dateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Poll")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: questionController,
              decoration: const InputDecoration(
                labelText: "Question",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ...optionControllers.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: c,
                  decoration: const InputDecoration(
                    labelText: "Option",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedClass,
              decoration: const InputDecoration(
                labelText: "Select Class",
                border: OutlineInputBorder(),
              ),
              items: [
                "CS1",
                "CS2",
                "CS3",
                "CS4",
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => selectedClass = val),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDateTime(true),
                    child: Text(
                      startTime == null
                          ? "Pick Start Time"
                          : startTime.toString().split('.')[0],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDateTime(false),
                    child: Text(
                      endTime == null
                          ? "Pick End Time"
                          : endTime.toString().split('.')[0],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createPoll,
              child: const Text("Create Poll"),
            ),
          ],
        ),
      ),
    );
  }
}
