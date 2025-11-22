import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherPollPage extends StatefulWidget {
  const TeacherPollPage({super.key});

  @override
  State<TeacherPollPage> createState() => _TeacherPollPageState();
}

class _TeacherPollPageState extends State<TeacherPollPage> {
  final questionController = TextEditingController();
  final List<TextEditingController> optionControllers = [];

  DateTime? startTime;
  DateTime? endTime;
  String? selectedClass;

  @override
  void initState() {
    super.initState();
    optionControllers.add(TextEditingController()); // start with 1 option
  }

  void addOption() {
    setState(() {
      optionControllers.add(TextEditingController());
    });
  }

  void removeOption(int index) {
    setState(() {
      optionControllers[index].dispose();
      optionControllers.removeAt(index);
    });
  }

  void createPoll() async {
    if (questionController.text.isEmpty ||
        optionControllers.any((c) => c.text.isEmpty) ||
        startTime == null ||
        endTime == null ||
        selectedClass == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

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

    // Clear all
    questionController.clear();
    for (var c in optionControllers) {
      c.clear();
    }
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
            // Question
            TextField(
              controller: questionController,
              decoration: const InputDecoration(
                labelText: "Question",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Options
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: optionControllers.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextField(
                          controller: optionControllers[index],
                          decoration: InputDecoration(
                            labelText: "Option ${index + 1}",
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (optionControllers.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () => removeOption(index),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),

            // Add new option
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: addOption,
                icon: const Icon(Icons.add),
                label: const Text("Add Option"),
              ),
            ),
            const SizedBox(height: 20),

            // Class selector
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

            // Start & End Time
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

            // Create Poll Button
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
