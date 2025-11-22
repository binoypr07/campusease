// lib/views/student/student_attendance.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String? classYear; // student's classYear (CS1, PHY2, etc.)
  Map<String, dynamic> attendanceMap = {}; // all date -> value pairs
  bool loading = true;

  // month/year selectors
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadStudentAndAttendance();
  }

  Future<void> _loadStudentAndAttendance() async {
    setState(() => loading = true);

    try {
      // load student info
      var userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        classYear = (userDoc.data() ?? {})['classYear'] as String? ?? '';
      }

      // load attendance doc for this student (document id = student uid)
      var attDoc = await _db.collection('attendance').doc(uid).get();
      if (attDoc.exists && attDoc.data() != null) {
        attendanceMap = Map<String, dynamic>.from(attDoc.data()!);
      } else {
        attendanceMap = {};
      }
    } catch (e) {
      print("Attendance load error: $e");
      Get.snackbar("Error", "Failed to load attendance",
          backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
    }

    setState(() => loading = false);
  }

  // returns a list of MapEntries (dateString -> value) filtered by selected month/year
  List<MapEntry<String, dynamic>> _filteredForMonth(int y, int m) {
    List<MapEntry<String, dynamic>> all = attendanceMap.entries.toList();

    return all.where((e) {
      try {
        DateTime dt = DateFormat('yyyy-MM-dd').parse(e.key);
        return dt.year == y && dt.month == m;
      } catch (ex) {
        return false;
      }
    }).toList()
      ..sort((a, b) {
        DateTime da = DateFormat('yyyy-MM-dd').parse(a.key);
        DateTime db = DateFormat('yyyy-MM-dd').parse(b.key);
        return da.compareTo(db);
      });
  }

  // compute stats for selected month
  Map<String, dynamic> _computeStats(int y, int m) {
    var entries = _filteredForMonth(y, m);

    int workingDays = entries.length; // only days teacher marked
    int presentCount = entries.where((e) => (e.value ?? 0) == 1.0).length;
    int halfCount = entries.where((e) => (e.value ?? 0) == 0.5).length;
    int absentCount = entries.where((e) => (e.value ?? 0) == 0.0).length;

    double presentEquivalent = presentCount + (0.5 * halfCount);
    double percent = workingDays > 0 ? (presentEquivalent / workingDays) * 100 : 0.0;

    return {
      'workingDays': workingDays,
      'presentCount': presentCount,
      'halfCount': halfCount,
      'absentCount': absentCount,
      'percent': percent,
    };
  }

  // Builds month dropdown (free selection)
  Widget _monthYearControls() {
    // years range: from 2022 to current year+1 (tweak if needed)
    int currentYear = DateTime.now().year;
    List<int> years = [for (int i = 2022; i <= currentYear; i++) i];

    return Row(
      children: [
        // Month
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: selectedMonth,
            decoration: const InputDecoration(labelText: "Month"),
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            items: List.generate(12, (i) {
              int month = i + 1;
              return DropdownMenuItem(
                value: month,
                child: Text(DateFormat.MMMM().format(DateTime(0, month))),
              );
            }),
            onChanged: (v) {
              if (v == null) return;
              setState(() => selectedMonth = v);
            },
          ),
        ),

        const SizedBox(width: 12),

        // Year
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: selectedYear,
            decoration: const InputDecoration(labelText: "Year"),
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            items: years
                .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => selectedYear = v);
            },
          ),
        ),
      ],
    );
  }

  // Format attendance status text
  String _statusText(dynamic val) {
    if (val == null) return "Holiday"; // teacher didn't mark (shouldn't appear here because we filter only marked)
    if (val == 1.0 || val == 1) return "Present";
    if (val == 0.5 || val == 0.5) return "Half Day";
    if (val == 0.0 || val == 0) return "Absent";
    return val.toString();
  }

  Color _statusColor(dynamic val) {
    if (val == null) return Colors.grey;
    if (val == 1.0 || val == 1) return Colors.green;
    if (val == 0.5 || val == 0.5) return Colors.orange;
    if (val == 0.0 || val == 0) return Colors.red;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return  Scaffold(
        appBar: AppBar(title: Text("Attendance")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // stats
    var stats = _computeStats(selectedYear, selectedMonth);
    var entries = _filteredForMonth(selectedYear, selectedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text("My Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: class info
            if ((classYear ?? '').isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Class: ${classYear!}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),

            const SizedBox(height: 12),

            // month/year controls
            _monthYearControls(),

            const SizedBox(height: 16),

            // Stats card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn("Working\nDays", stats['workingDays'].toString()),
                    _statColumn("Present", stats['presentCount'].toString()),
                    _statColumn("Half\nDays", stats['halfCount'].toString()),
                    _statColumn("Absent", stats['absentCount'].toString()),
                    _statColumn(
                        "Percent", stats['workingDays'] > 0 ? "${stats['percent'].toStringAsFixed(1)}%" : "-"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // If no working days → show message (holiday)
            if (stats['workingDays'] == 0)
              Expanded(
                child: Center(
                  child: Text(
                    "No attendance recorded for ${DateFormat.MMMM().format(DateTime(selectedYear, selectedMonth))}.\n(Teacher did not mark — treated as holiday)",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              // Daily list
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, idx) {
                    var e = entries[idx];
                    DateTime dt = DateFormat('yyyy-MM-dd').parse(e.key);
                    String dateStr = DateFormat('EEE, d MMM yyyy').format(dt);
                    var val = e.value;
                    return Card(
                      child: ListTile(
                        title: Text(dateStr, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(_statusText(val), style: TextStyle(color: _statusColor(val))),
                        trailing: Text(
                          val == null ? "-" : (val == 1.0 ? "1.0" : val.toString()),
                          style: TextStyle(color: _statusColor(val)),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
