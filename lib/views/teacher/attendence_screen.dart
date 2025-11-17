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
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  Map<String, double> attendanceData = {};

  @override
  void initState() {
    super.initState();
    loadTeacherClass();
  }

  // ---------------------------------------------------------
  // LOAD ASSIGNED CLASS
  // ---------------------------------------------------------
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ------------------- DATE PICKER -----------------------
          Center(
            child: Text(
              "Date: $selectedDate",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),

          Center(
            child: ElevatedButton(
              onPressed: pickDate,
              child: const Text("Pick Date"),
            ),
          ),

          const SizedBox(height: 12),

          // ------------------- STUDENT LIST -----------------------
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
                      child: CircularProgressIndicator(
                    color: Colors.white,
                  ));
                }

                var students = snapshot.data!.docs;

                if (students.isEmpty) {
                  return Center(
                    child: Text(
                      "No students in $assignedClass",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var stu = students[index];
                    String stuId = stu.id;

                    double value =
                        attendanceData[stuId] ?? 1.0; // default present

                    return Card(
                      color: Colors.black,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Colors.white, width: 1.3),
                      ),
                      child: ListTile(
                        title: Text(
                          stu["name"],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Admission No: ${stu['admissionNumber']}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: DropdownButton<double>(
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white),
                          value: value,
                          items: const [
                            DropdownMenuItem(
                                value: 1.0, child: Text("Present")),
                            DropdownMenuItem(
                                value: 0.5, child: Text("Half Day")),
                            DropdownMenuItem(
                                value: 0.0, child: Text("Absent")),
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

          // ---------------- SAVE BUTTON ------------------
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
    );
  }

  // ------------------ DATE PICKER ------------------
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onSurface: Colors.white,
              surface: Colors.black,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = DateFormat("yyyy-MM-dd").format(picked);
      });
    }
  }

  // ---------------- SAVE ATTENDANCE ---------------------
  Future<void> saveAttendance() async {
    for (var entry in attendanceData.entries) {
      String stuId = entry.key;
      double value = entry.value;

      await FirebaseFirestore.instance
          .collection("attendance")
          .doc(stuId)
          .set(
        {selectedDate: value},
        SetOptions(merge: true),
      );
    }

    Get.snackbar(
      "Success",
      "Attendance saved!",
      backgroundColor: Colors.black,
      colorText: Colors.white,
    );
  }
}
