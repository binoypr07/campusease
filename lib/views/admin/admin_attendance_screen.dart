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

      await loadAllAttendance();
    } catch (_) {
      Get.snackbar("Error", "Failed to load students");
    }
    setState(() => loading = false);
  }

  // ---------------- CORE FIX ----------------

  Future<void> loadAllAttendance() async {
    setState(() => loading = true);
    allStudentAttendance.clear();
    allDates.clear();

    Set<String> dateSet = {};

    for (var s in students) {
      var doc = await _db.collection('attendance').doc(s['id']).get();
      Map<String, dynamic> raw = doc.exists ? doc.data()! : {};

      Map<String, dynamic> filtered = {};

      raw.forEach((k, v) {
        try {
          final d = DateFormat('yyyy-MM-dd').parse(k);
          if (d.year == selectedYear && d.month == selectedMonth) {
            filtered[k] = v;
            dateSet.add(k);
          }
        } catch (_) {}
      });

      allStudentAttendance[s['id']] = {
        'name': s['name'],
        'attendance': filtered,
      };
    }

    allDates = dateSet.toList()..sort();
    setState(() => loading = false);
  }

  // ---------------- PDF EXPORT ----------------

  Future<void> exportClassPDF() async {
    final pdf = pw.Document();
    final monthName = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(selectedYear, selectedMonth));

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Attendance Report: $selectedClass",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text("Period: $monthName", style: pw.TextStyle(fontSize: 14)),
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

  // Helper for Cell Color
  Color _getStatusColor(dynamic value) {
    if (value == 1) return Colors.green.shade700;
    if (value == 0.5) return Colors.orange.shade700;
    return Colors.red.shade700;
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Department",
                        ),
                        value: selectedDepartment,
                        items: departments
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
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
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) async {
                            selectedClass = v;
                            await loadStudents(selectedDepartment!, v!);
                          },
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: "Select Month",
                              ),
                              value: selectedMonth,
                              items: List.generate(12, (index) => index + 1)
                                  .map((m) {
                                    return DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        DateFormat(
                                          'MMMM',
                                        ).format(DateTime(2024, m)),
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (v) {
                                setState(() => selectedMonth = v!);
                                if (selectedClass != null) loadAllAttendance();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: "Select Year",
                              ),
                              value: selectedYear,
                              items:
                                  [
                                    DateTime.now().year,
                                    DateTime.now().year - 1,
                                  ].map((y) {
                                    return DropdownMenuItem(
                                      value: y,
                                      child: Text(y.toString()),
                                    );
                                  }).toList(),
                              onChanged: (v) {
                                setState(() => selectedYear = v!);
                                if (selectedClass != null) loadAllAttendance();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scrollable Table Area
                if (allDates.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            const Color.fromARGB(255, 7, 7, 7),
                          ),
                          columns: [
                            const DataColumn(
                              label: Text(
                                "Student",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...allDates.map(
                              (d) => DataColumn(
                                label: Text(
                                  DateFormat(
                                    'dd MMM',
                                  ).format(DateTime.parse(d)),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                      style: TextStyle(
                                        color: _getStatusColor(v),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  )
                else if (selectedClass != null && !loading)
                  const Expanded(
                    child: Center(child: Text("No attendance records found.")),
                  ),
              ],
            ),
    );
  }
}
