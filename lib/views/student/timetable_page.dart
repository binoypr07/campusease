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
    try {
      var doc = await FirebaseFirestore.instance
          .collection('timetables')
          .doc(widget.className)
          .get();

      if (doc.exists) {
        List data = doc['entries'] ?? [];
        timetable = data.map((e) => TimetableEntry(
          subject: e['subject'] ?? '',
          time: e['time'] ?? '',
          teacher: e['teacher'] ?? '',
          room: e['room'] ?? '',
        )).toList();
      }
    } catch (e) {
      print("Error loading timetable: $e");
      timetable = [];
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Time Table")),
      body: ListView.builder(
        itemCount: timetable.length,
        itemBuilder: (context, index) {
          return TimetableCardWidget(entry: timetable[index]);
        },
      ),
    );
  }
}