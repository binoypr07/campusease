import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../student/timetable/time_table_entry.dart';
import '../../student/timetable/timetable_card.dart';

class EditableTimetablePage extends StatefulWidget {
  final String className;
  const EditableTimetablePage({super.key, required this.className});

  @override
  State<EditableTimetablePage> createState() => _EditableTimetablePageState();
}

class _EditableTimetablePageState extends State<EditableTimetablePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<TimetableEntry> entries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    try {
      var doc = await firestore
          .collection('timetables')
          .doc(widget.className)
          .get();

      if (doc.exists) {
        List data = doc['entries'] ?? [];
        entries = data
            .map(
              (e) => TimetableEntry(
                subject: e['subject'] ?? '',
                time: e['time'] ?? '',
                teacher: e['teacher'] ?? '',
                room: e['room'] ?? '',
              ),
            )
            .toList();
      }
    } catch (e) {
      print("Error loading timetable: $e");
      entries = [];
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveTimetable() async {
    try {
      List data = entries
          .map(
            (e) => {
              'subject': e.subject,
              'time': e.time,
              'teacher': e.teacher,
              'room': e.room,
            },
          )
          .toList();

      await firestore.collection('timetables').doc(widget.className).set({
        'entries': data,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Timetable saved')));
    } catch (e) {
      print("Error saving timetable: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save timetable')));
    }
  }

  void editEntry(int index) {
    final entry = entries[index];
    final subjectController = TextEditingController(text: entry.subject);
    final timeController = TextEditingController(text: entry.time);
    final teacherController = TextEditingController(text: entry.teacher);
    final roomController = TextEditingController(text: entry.room);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Entry"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: teacherController,
                decoration: const InputDecoration(
                  labelText: 'Teacher',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                entries[index] = TimetableEntry(
                  subject: subjectController.text,
                  time: timeController.text,
                  teacher: teacherController.text,
                  room: roomController.text,
                );
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Timetable - ${widget.className}"),
        actions: [
          IconButton(
            tooltip: "Save",
            onPressed: saveTimetable,
            icon: const Icon(Icons.cloud_upload),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => editEntry(index),
                    child: TimetableCardWidget(entry: entry),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Delete Entry',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Entry"),
                        content: const Text(
                          "Are you sure you want to delete this entry?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                entries.removeAt(index);
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            entries.add(
              TimetableEntry(subject: '', time: '', teacher: '', room: ''),
            );
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
