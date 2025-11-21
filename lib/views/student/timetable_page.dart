import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'timetable_card.dart';
import '../student/time_table_entry.dart';

class TimetablePage extends StatefulWidget {
  final String className;
  const TimetablePage({super.key, required this.className});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  List<TimetableEntry> timetable = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    print("DEBUG: Loading timetable for class → ${widget.className}");

    try {
      var doc = await FirebaseFirestore.instance
          .collection('timetables')
          .doc(widget.className)
          .get();

      print("DEBUG: doc.exists → ${doc.exists}");
      print("DEBUG: Firestore document → ${doc.data()}");

      if (doc.exists) {
        List data = doc.data()?['entries'] ?? [];

        print("DEBUG: Entries length → ${data.length}");

        timetable = data.map((e) {
          print("DEBUG: Entry loaded → $e"); // prints each timetable item

          return TimetableEntry(
            subject: e['subject'] ?? '',
            time: e['time'] ?? '',
            teacher: e['teacher'] ?? '',
            room: e['room'] ?? '',
          );
        }).toList();
      } else {
        print("DEBUG: NO timetable found for this class!");
      }
    } catch (e) {
      print("ERROR loading timetable → $e");
      timetable = [];
    } finally {
      setState(() => loading = false);
      print("DEBUG: UI updated");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Time Table")),
      body: ListView.builder(
        itemCount: timetable.length,
        itemBuilder: (context, index) {
          print("DEBUG: Rendering entry index → $index");
          return TimetableCardWidget(entry: timetable[index]);
        },
      ),
    );
  }
}
