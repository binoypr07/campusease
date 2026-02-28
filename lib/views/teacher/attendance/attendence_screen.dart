import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? assignedClass;

  DateTime selectedDate = DateTime.now();
  String selectedDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());

  Map<String, double> attendanceData = {};
  bool _isEndingSemester = false;

  @override
  void initState() {
    super.initState();
    loadTeacherClass().then((_) => loadAttendanceForDate());
  }

  Future<void> loadTeacherClass() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    if (!doc.exists) return;
    setState(() {
      assignedClass = doc["assignedClass"];
    });
  }

  Future<void> loadAttendanceForDate() async {
    if (assignedClass == null) return;

    var snap = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "student")
        .where("classYear", isEqualTo: assignedClass)
        .get();

    Map<String, double> fresh = {};
    for (var stu in snap.docs) {
      fresh[stu.id] = 1.0;
    }
    for (var stu in snap.docs) {
      var attDoc = await FirebaseFirestore.instance
          .collection("attendance")
          .doc(stu.id)
          .get();
      if (attDoc.exists && attDoc.data()!.containsKey(selectedDateString)) {
        fresh[stu.id] = (attDoc.data()![selectedDateString] as num).toDouble();
      }
    }
    setState(() => attendanceData = fresh);
  }

  void _openAttendanceReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TeacherAttendanceReportScreen(assignedClass: assignedClass!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (assignedClass == null || assignedClass!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text("Attendance")),
        body: const Center(
          child: Text(
            "Please assign a class first",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Take Attendance"),
        actions: [
          PopupMenuButton<String>(
            color: const Color(0xFF1F2C34),
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'view_attendance') {
                _openAttendanceReport();
              } else if (value == 'end_semester') {
                if (!_isEndingSemester) _confirmEndSemester();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_attendance',
                child: Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "View Attendance",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'end_semester',
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      color: _isEndingSemester ? Colors.grey : Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEndingSemester ? "Ending…" : "End Semester",
                      style: TextStyle(
                        color: _isEndingSemester
                            ? Colors.grey
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Text(
                "Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => pickDate(context),
              child: const Text("Pick Date"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .where("role", isEqualTo: "student")
                    .where("classYear", isEqualTo: assignedClass)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  var students = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      var stu = students[index];
                      String stuId = stu.id;
                      double value = attendanceData[stuId] ?? 1.0;
                      return Card(
                        color: Colors.black,
                        child: ListTile(
                          title: Text(
                            stu["name"],
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: DropdownButton<double>(
                            dropdownColor: Colors.black,
                            value: value,
                            items: const [
                              DropdownMenuItem(
                                value: 1.0,
                                child: Text("Present"),
                              ),
                              DropdownMenuItem(
                                value: 0.5,
                                child: Text("Half Day"),
                              ),
                              DropdownMenuItem(
                                value: 0.0,
                                child: Text("Absent"),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => attendanceData[stuId] = val!),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveAttendance,
                  child: const Text("Save Attendance"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedDateString = DateFormat("yyyy-MM-dd").format(picked);
        attendanceData = {};
      });
      await loadAttendanceForDate();
    }
  }

  Future<void> saveAttendance() async {
    if (attendanceData.isEmpty) {
      Get.snackbar(
        "No Data",
        "No attendance marked",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      final batch = FirebaseFirestore.instance.batch();
      attendanceData.forEach((stuId, value) {
        final ref = FirebaseFirestore.instance
            .collection("attendance")
            .doc(stuId);
        batch.set(ref, {selectedDateString: value}, SetOptions(merge: true));
      });
      await batch.commit();
      Get.snackbar(
        "Success",
        "Attendance saved!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _confirmEndSemester() {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF1F2C34),
      titleStyle: const TextStyle(color: Colors.white),
      title: "End Semester?",
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "All students in this class will be moved to the next semester. "
          "Attendance will start counting from 0 for the new semester.",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
      radius: 14,
      textCancel: "Cancel",
      textConfirm: "End Semester",
      cancelTextColor: Colors.white,
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () async {
        Get.back();
        await _endSemester();
      },
    );
  }

  Future<void> _endSemester() async {
    if (assignedClass == null) return;
    setState(() => _isEndingSemester = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: "student")
          .where("classYear", isEqualTo: assignedClass)
          .get();

      if (snap.docs.isEmpty) {
        Get.snackbar(
          "No Students",
          "No students found in this class.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final newStart = DateTime.now();
      final newEnd = DateTime(
        newStart.year,
        newStart.month + 6,
        newStart.day,
      ).subtract(const Duration(days: 1));

      for (var stuDoc in snap.docs) {
        final data = stuDoc.data();
        final currentSemester = (data['currentSemester'] as int?) ?? 1;
        batch.update(
          FirebaseFirestore.instance.collection("users").doc(stuDoc.id),
          {
            'currentSemester': currentSemester + 1,
            'semesterStartDate': Timestamp.fromDate(newStart),
            'semesterEndDate': Timestamp.fromDate(newEnd),
          },
        );
      }

      await batch.commit();
      Get.snackbar(
        "Semester Ended",
        "Students moved to next semester. Attendance reset to 0.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to end semester: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isEndingSemester = false);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Teacher Attendance Report Screen
// ════════════════════════════════════════════════════════════════════════════

class TeacherAttendanceReportScreen extends StatefulWidget {
  final String assignedClass;
  const TeacherAttendanceReportScreen({super.key, required this.assignedClass});

  @override
  State<TeacherAttendanceReportScreen> createState() =>
      _TeacherAttendanceReportScreenState();
}

class _TeacherAttendanceReportScreenState
    extends State<TeacherAttendanceReportScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  List<Map<String, dynamic>> students = [];
  Map<String, Map<String, dynamic>> allStudentAttendance = {};
  List<String> allDates = [];
  bool loading = true;
  bool _sendingToChat = false;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() => loading = true);
    try {
      var snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classYear', isEqualTo: widget.assignedClass)
          .get();

      students = snap.docs.map((d) => {'id': d.id, 'name': d['name']}).toList();
      await loadAllAttendance();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load students",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    setState(() => loading = false);
  }

  Future<void> loadAllAttendance() async {
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
    setState(() {});
  }

  // ── Build PDF bytes — returns Uint8List to satisfy Printing.layoutPdf ───
  Future<Uint8List> _buildPdfBytes() async {
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
              "Attendance Report: ${widget.assignedClass}",
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

    // pdf.save() returns List<int>; wrap in Uint8List for Printing compatibility
    return Uint8List.fromList(await pdf.save());
  }
  // ────────────────────────────────────────────────────────────────────────

  Future<void> exportPDF() async {
    final bytes = await _buildPdfBytes();
    // bytes is now Uint8List — no type error
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  // ── Upload PDF to Cloudinary then post to class chat ─────────────────────
  Future<void> _sendPDFToChat() async {
    if (_sendingToChat) return;
    setState(() => _sendingToChat = true);

    try {
      final monthName = DateFormat(
        'MMMM yyyy',
      ).format(DateTime(selectedYear, selectedMonth));
      final fileName = "Attendance_${widget.assignedClass}_$monthName.pdf"
          .replaceAll(' ', '_');

      // 1. Build PDF bytes
      final bytes = await _buildPdfBytes();

      // 2. Upload to Cloudinary as raw file
      const String cloudName = "dqw6gqdfn";
      const String uploadPreset = "my_voice_preset";
      final uploadUrl = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/upload",
      );

      var request = http.MultipartRequest("POST", uploadUrl);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['resource_type'] = 'raw';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes, // Uint8List is a subtype of List<int> — works fine here too
          filename: fileName,
        ),
      );

      var streamed = await request.send();
      var response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw Exception("Upload failed: ${response.statusCode}");
      }

      final pdfUrl = jsonDecode(response.body)['secure_url'] as String;

      // 3. Get current teacher info
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final senderName = user.data()?['name'] ?? 'Teacher';
      final senderRole = user.data()?['role'] ?? 'teacher';

      // 4. Post pdf message to class chat
      await FirebaseFirestore.instance
          .collection('class_chats')
          .doc(widget.assignedClass)
          .collection('messages')
          .add({
            'senderId': uid,
            'senderName': senderName,
            'senderRole': senderRole,
            'message': pdfUrl,
            'messageType': 'pdf',
            'fileName': fileName,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'delivered',
            'seenBy': [uid],
          });

      Get.snackbar(
        "Sent!",
        "Attendance PDF sent to ${widget.assignedClass} chat 📄",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send PDF: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _sendingToChat = false);
    }
  }
  // ────────────────────────────────────────────────────────────────────────

  Color _statusColor(dynamic v) {
    if (v == 1) return Colors.green.shade400;
    if (v == 0.5) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(selectedYear, selectedMonth));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C34),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Attendance Report",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.assignedClass,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          if (_sendingToChat)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (allDates.isNotEmpty)
            PopupMenuButton<String>(
              color: const Color(0xFF1F2C34),
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) {
                if (v == 'pdf') exportPDF();
                if (v == 'send_chat') _sendPDFToChat();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Export PDF",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'send_chat',
                  child: Row(
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: Color(0xFF00A884),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Send to Class Chat",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Container(
                  color: const Color(0xFF1F2C34),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          dropdownColor: const Color(0xFF1F2C34),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Month",
                            labelStyle: const TextStyle(color: Colors.white60),
                            filled: true,
                            fillColor: const Color(0xFF2A3942),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          value: selectedMonth,
                          items: List.generate(12, (i) => i + 1).map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(
                                DateFormat('MMMM').format(DateTime(2024, m)),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) async {
                            setState(() => selectedMonth = v!);
                            await loadAllAttendance();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          dropdownColor: const Color(0xFF1F2C34),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Year",
                            labelStyle: const TextStyle(color: Colors.white60),
                            filled: true,
                            fillColor: const Color(0xFF2A3942),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          value: selectedYear,
                          items: [DateTime.now().year, DateTime.now().year - 1]
                              .map((y) {
                                return DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    y.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (v) async {
                            setState(() => selectedYear = v!);
                            await loadAllAttendance();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: const Color(0xFF2A3942),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    monthName,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
                if (allDates.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFF1F2C34),
                          ),
                          dataRowColor: WidgetStateProperty.all(
                            const Color(0xFF121212),
                          ),
                          columnSpacing: 20,
                          columns: [
                            const DataColumn(
                              label: Text(
                                "Student",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...allDates.map(
                              (d) => DataColumn(
                                label: Text(
                                  DateFormat(
                                    'dd\nMMM',
                                  ).format(DateTime.parse(d)),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
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
                            int present = 0, half = 0, absent = 0;
                            for (final d in allDates) {
                              final v = att[d];
                              if (v == 1)
                                present++;
                              else if (v == 0.5)
                                half++;
                              else
                                absent++;
                            }
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "P:$present H:$half A:$absent",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...allDates.map((d) {
                                  final v = att[d];
                                  final label = v == 1
                                      ? "P"
                                      : v == 0.5
                                      ? "H"
                                      : v == 0.0
                                      ? "A"
                                      : "-";
                                  return DataCell(
                                    Center(
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: v != null
                                              ? _statusColor(v).withOpacity(0.2)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: v != null
                                                  ? _statusColor(v)
                                                  : Colors.white24,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
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
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 52,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No attendance records\nfor $monthName",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
