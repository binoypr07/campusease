import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:get/get.dart';

class AdminInternalMarksScreen extends StatefulWidget {
  const AdminInternalMarksScreen({super.key});

  @override
  State<AdminInternalMarksScreen> createState() =>
      _AdminInternalMarksScreenState();
}

class _AdminInternalMarksScreenState extends State<AdminInternalMarksScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? selectedDepartment;
  String? selectedClass;

  List<String> departments = [];
  List<String> classes = [];
  bool loading = true;

  List<Map<String, dynamic>> consolidatedData = [];
  List<String> allSubjects = [];

  @override
  void initState() {
    super.initState();
    loadDepartments();
  }

  // ---------------- LOAD FILTERS ----------------

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

  // ---------------- LOAD MARKS ----------------

  Future<void> _fetchClassMarks(String cls) async {
    try {
      setState(() => loading = true);

      // 1. Get students in the selected class
      final usersSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classYear', isEqualTo: cls)
          .get();

      Map<String, String> studentNames = {
        for (var doc in usersSnap.docs) doc.id: doc.data()['name'] ?? 'Unknown',
      };

      // 2. Get all mark entries
      final marksSnap = await _db
          .collection('internal_marks')
          .doc('${cls}_marks')
          .collection('students')
          .get();

      Set<String> subjectSet = {};
      List<Map<String, dynamic>> tempList = [];

      for (var doc in marksSnap.docs) {
        final data = doc.data();
        final studentId = doc.id;

        if (studentNames.containsKey(studentId)) {
          subjectSet.addAll(data.keys);
          tempList.add({'name': studentNames[studentId], 'marks': data});
        }
      }

      setState(() {
        allSubjects = subjectSet.toList()..sort();
        consolidatedData = tempList
          ..sort((a, b) => a['name'].compareTo(b['name']));
        loading = false;
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to load marks");
      setState(() => loading = false);
    }
  }

  // ---------------- PDF EXPORT ----------------

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text("Internal Marks Report - $selectedClass"),
          ),
          pw.TableHelper.fromTextArray(
            headers: ['Student Name', ...allSubjects],
            data: consolidatedData.map((row) {
              return [
                row['name'],
                ...allSubjects.map(
                  (sub) => row['marks'][sub]?.toString() ?? '-',
                ),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Internal Marks"),
        actions: [
          if (consolidatedData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
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
                          consolidatedData.clear();
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
                            await _fetchClassMarks(v!);
                          },
                        ),
                    ],
                  ),
                ),

                // Scrollable Table Area
                if (consolidatedData.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            const Color.fromARGB(255, 0, 0, 0),
                          ),
                          columns: [
                            const DataColumn(
                              label: Text(
                                "Student Name",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            ...allSubjects.map(
                              (s) => DataColumn(
                                label: Text(
                                  s,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          rows: consolidatedData.map((row) {
                            return DataRow(
                              cells: [
                                DataCell(Text(row['name'])),
                                ...allSubjects.map(
                                  (sub) => DataCell(
                                    Text(row['marks'][sub]?.toString() ?? "-"),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  )
                else if (selectedClass != null && !loading)
                  const Expanded(
                    child: Center(
                      child: Text("No marks found for this class."),
                    ),
                  ),
              ],
            ),
    );
  }
}
