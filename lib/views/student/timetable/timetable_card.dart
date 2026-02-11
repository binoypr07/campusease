import 'package:flutter/material.dart';
import 'time_table_entry.dart';

class TimetableCardWidget extends StatelessWidget {
  final TimetableEntry entry;

  const TimetableCardWidget({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Time: ${entry.time}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    "Teacher: ${entry.teacher}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    "Room: ${entry.room}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
