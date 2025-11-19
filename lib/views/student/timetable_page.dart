import 'package:flutter/material.dart';
import 'timetable_card.dart';
import 'timetable_data.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
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
