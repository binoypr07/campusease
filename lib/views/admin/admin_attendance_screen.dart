import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? selectedDepartment;
  String? selectedClass;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  List<String> departments = [];
  List<String> classes = [];
  List<Map<String, dynamic>> students = [];
  bool loading = true;

  Map<String, Map<String, dynamic>> allStudentAttendance = {};
  List<String> allDates = [];

  @override
  void initState() {
    super.initState();
    loadDepartments();
  }

  // ---------------- LOAD DATA ----------------

  Future<void> loadDepartments() async {
    setState(() => loading = true);
    try {
      var snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      departments = snap.docs
          .map((e) => (e.data()['department'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      Get.snackbar("Error", "Failed to load departments");
    }
    setState(() => loading = false);
  }

  Future<void> loadClasses(String department) async {
    setState(() => loading = true);
    try {
      var snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('department', isEqualTo: department)
          .get();

      classes = snap.docs
          .map((e) => (e.data()['classYear'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      Get.snackbar("Error", "Failed to load classes");
    }
    setState(() => loading = false);
  }

  Future<void> loadStudents(String dept, String cls) async {
    setState(() => loading = true);
    try {
      var snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('department', isEqualTo: dept)
          .where('classYear', isEqualTo: cls)
          .get();

      students = snap.docs.map((d) => {'id': d.id, 'name': d['name']}).toList();

      await loadAllAttendance(); // ✅ load attendance after students loaded
    } catch (_) {
      Get.snackbar("Error", "Failed to load students");
    }
    setState(() => loading = false);
  }

  // ---------------- CORE FIX ----------------

  Future<void> loadAllAttendance() async {
    allStudentAttendance.clear();
    allDates.clear();

    Set<String> dateSet = {}; // collect ALL dates

    for (var s in students) {
      var doc = await _db.collection('attendance').doc(s['id']).get();
      Map<String, dynamic> raw = doc.exists ? doc.data()! : {};

      Map<String, dynamic> filtered = {};

      raw.forEach((k, v) {
        try {
          final d = DateFormat('yyyy-MM-dd').parse(k);
          if (d.year == selectedYear && d.month == selectedMonth) {
            filtered[k] = v;
            dateSet.add(k); // collect all dates across students
          }
        } catch (_) {}
      });

      allStudentAttendance[s['id']] = {
        'name': s['name'],
        'attendance': filtered,
      };
    }

    allDates = dateSet.toList()..sort(); // sorted list of all dates
    setState(() {});
  }

  // ---------------- PDF EXPORT ----------------

  Future<void> exportClassPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Class Attendance", style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: [
                "Student",
                ...allDates.map(
                  (d) => DateFormat('dd MMM').format(DateTime.parse(d)),
                ),
              ],
              data: allStudentAttendance.values.map((s) {
                final att = Map<String, dynamic>.from(s['attendance']);
                return [
                  s['name'],
                  ...allDates.map((d) {
                    final v = att[d];
                    return v == 1
                        ? "P"
                        : v == 0.5
                        ? "H"
                        : "A";
                  }),
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Attendance Dashboard"),
        actions: [
          if (students.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'pdf') exportClassPDF();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'pdf', child: Text("Export PDF")),
              ],
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Department"),
                    value: selectedDepartment,
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) async {
                      selectedDepartment = v;
                      selectedClass = null;
                      students.clear();
                      allStudentAttendance.clear();
                      await loadClasses(v!);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  if (classes.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Class"),
                      value: selectedClass,
                      items: classes
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) async {
                        selectedClass = v;
                        await loadStudents(selectedDepartment!, v!);
                      },
                    ),
                  const SizedBox(height: 12),
                  if (allDates.isNotEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            const DataColumn(label: Text("Student")),
                            ...allDates.map(
                              (d) => DataColumn(
                                label: Text(
                                  DateFormat(
                                    'dd MMM',
                                  ).format(DateTime.parse(d)),
                                ),
                              ),
                            ),
                          ],
                          rows: allStudentAttendance.values.map((s) {
                            final att = Map<String, dynamic>.from(
                              s['attendance'],
                            );
                            return DataRow(
                              cells: [
                                DataCell(Text(s['name'])),
                                ...allDates.map((d) {
                                  final v = att[d];
                                  return DataCell(
                                    Text(
                                      v == 1
                                          ? "P"
                                          : v == 0.5
                                          ? "H"
                                          : "A",
                                    ),
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
