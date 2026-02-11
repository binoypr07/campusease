// lib/views/student/student_attendance.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class StudentAttendanceScreen extends StatefulWidget {
  // Removed const to avoid Web compilation errors
  StudentAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String? classYear;
  Map<String, dynamic> attendanceMap = {};
  bool loading = true;

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
      // Load student info
      var userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        classYear = (userDoc.data() ?? {})['classYear'] as String? ?? '';
      }

      // Load attendance data
      var attDoc = await _db.collection('attendance').doc(uid).get();
      if (attDoc.exists && attDoc.data() != null) {
        attendanceMap = Map<String, dynamic>.from(attDoc.data()!);
      } else {
        attendanceMap = {};
      }
    } catch (e) {
      print("Attendance load error: $e");
      Get.snackbar(
        "Error",
        "Failed to load attendance",
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
    }

    setState(() => loading = false);
  }

  // Filter attendance for selected month/year
  List<MapEntry<String, dynamic>> _filteredForMonth(int y, int m) {
    return attendanceMap.entries.where((e) {
      try {
        DateTime dt = DateFormat('yyyy-MM-dd').parse(e.key);
        return dt.year == y && dt.month == m;
      } catch (_) {
        return false;
      }
    }).toList()..sort((a, b) {
      DateTime da = DateFormat('yyyy-MM-dd').parse(a.key);
      DateTime db = DateFormat('yyyy-MM-dd').parse(b.key);
      return da.compareTo(db);
    });
  }

  // Compute stats for month
  Map<String, dynamic> _computeStats(int y, int m) {
    var entries = _filteredForMonth(y, m);

    int workingDays = entries.length;
    int presentCount = entries.where((e) => (e.value ?? 0) == 1.0).length;
    int halfCount = entries.where((e) => (e.value ?? 0) == 0.5).length;
    int absentCount = entries.where((e) => (e.value ?? 0) == 0.0).length;

    double percent = 0.0;
    if (workingDays > 0) {
      percent = (presentCount + 0.5 * halfCount) / workingDays * 100;
    }

    return {
      'workingDays': workingDays,
      'presentCount': presentCount,
      'halfCount': halfCount,
      'absentCount': absentCount,
      'percent': percent,
    };
  }

  Widget _monthYearControls() {
    int currentYear = DateTime.now().year;
    List<int> years = [for (int i = 2022; i <= currentYear; i++) i];

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedMonth,
            decoration: InputDecoration(labelText: "Month"),
            items: List.generate(12, (i) {
              int month = i + 1;
              return DropdownMenuItem(
                value: month,
                child: Text(DateFormat.MMMM().format(DateTime(0, month))),
              );
            }),
            onChanged: (v) {
              if (v != null) setState(() => selectedMonth = v);
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedYear,
            decoration: InputDecoration(labelText: "Year"),
            items: years
                .map(
                  (y) => DropdownMenuItem(value: y, child: Text(y.toString())),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => selectedYear = v);
            },
          ),
        ),
      ],
    );
  }

  String _statusText(dynamic val) {
    if (val == null) return "Holiday";
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
      return Scaffold(
        appBar: AppBar(title: Text("Attendance")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    var stats = _computeStats(selectedYear, selectedMonth);
    var entries = _filteredForMonth(selectedYear, selectedMonth);

    return Scaffold(
      appBar: AppBar(title: Text("My Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if ((classYear ?? '').isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Class: $classYear",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            SizedBox(height: 12),
            _monthYearControls(),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn(
                      "Working\nDays",
                      stats['workingDays'].toString(),
                    ),
                    _statColumn("Present", stats['presentCount'].toString()),
                    _statColumn("Half\nDays", stats['halfCount'].toString()),
                    _statColumn("Absent", stats['absentCount'].toString()),
                    _statColumn(
                      "Percent",
                      stats['workingDays'] > 0
                          ? "${stats['percent'].toStringAsFixed(1)}%"
                          : "-",
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            if (stats['workingDays'] == 0)
              Expanded(
                child: Center(
                  child: Text(
                    "No attendance recorded for ${DateFormat.MMMM().format(DateTime(selectedYear, selectedMonth))}.\n(Teacher did not mark — treated as holiday)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, idx) {
                    var e = entries[idx];
                    DateTime dt = DateFormat('yyyy-MM-dd').parse(e.key);
                    return Card(
                      child: ListTile(
                        title: Text(
                          DateFormat('EEE, d MMM yyyy').format(dt),
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          _statusText(e.value),
                          style: TextStyle(color: _statusColor(e.value)),
                        ),
                        trailing: Text(
                          e.value == null
                              ? "-"
                              : (e.value == 1.0 ? "1.0" : e.value.toString()),
                          style: TextStyle(color: _statusColor(e.value)),
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
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
