import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

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

  @override
  void initState() {
    super.initState();
    loadTeacherClass();
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
      appBar: AppBar(title: const Text("Take Attendance")),
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

                  // ================= STEP 1: INITIALIZE ATTENDANCE FOR ALL STUDENTS =================
                  if (attendanceData.isEmpty) {
                    for (var s in students) {
                      attendanceData[s.id] = 1.0; // default = Present
                    }
                  }

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
                            onChanged: (val) {
                              setState(() {
                                attendanceData[stuId] = val!;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
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
      });
    }
  }

  // ================== SAVE ATTENDANCE WITH SNACKBAR ==================
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

      // REMOVED addPostFrameCallback - GetX handles its own timing
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
}
