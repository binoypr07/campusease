import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class ClassInternalMarksView extends StatefulWidget {
  final String className;
  const ClassInternalMarksView({super.key, required this.className});

  @override
  State<ClassInternalMarksView> createState() => _ClassInternalMarksViewState();
}

class _ClassInternalMarksViewState extends State<ClassInternalMarksView> {
  bool isLoading = true;
  List<Map<String, dynamic>> consolidatedData = [];
  List<String> allSubjects = [];

  @override
  void initState() {
    super.initState();
    _fetchClassMarks();
  }

  Future<void> _fetchClassMarks() async {
    try {
      setState(() => isLoading = true);

      // 1. Get all students in this class to get their names
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classYear', isEqualTo: widget.className)
          .get();

      Map<String, String> studentNames = {
        for (var doc in usersSnap.docs) doc.id: doc.data()['name'] ?? 'Unknown',
      };

      // 2. Get all mark entries for this class
      final marksSnap = await FirebaseFirestore.instance
          .collection('internal_marks')
          .doc('${widget.className}_marks')
          .collection('students')
          .get();

      Set<String> subjectSet = {};
      List<Map<String, dynamic>> tempList = [];

      for (var doc in marksSnap.docs) {
        final data = doc.data();
        final studentId = doc.id;

        // Only include if student belongs to this class
        if (studentNames.containsKey(studentId)) {
          subjectSet.addAll(data.keys);
          tempList.add({'name': studentNames[studentId], 'marks': data});
        }
      }

      setState(() {
        allSubjects = subjectSet.toList()..sort();
        consolidatedData = tempList
          ..sort((a, b) => a['name'].compareTo(b['name']));
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text("Internal Marks Report - ${widget.className}"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} Marks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: consolidatedData.isEmpty ? null : _generatePdf,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : consolidatedData.isEmpty
          ? const Center(child: Text("No marks found for this class"))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey),
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    children: [
                      // Header Row
                      TableRow(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        children: [
                          _buildCell("Student Name", isHeader: true),
                          ...allSubjects.map(
                            (s) => _buildCell(s, isHeader: true),
                          ),
                        ],
                      ),
                      // Data Rows
                      ...consolidatedData.map((row) {
                        return TableRow(
                          children: [
                            _buildCell(row['name']),
                            ...allSubjects.map(
                              (sub) => _buildCell(
                                row['marks'][sub]?.toString() ?? "-",
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
