import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAllStudentsScreen extends StatefulWidget {
  const AdminAllStudentsScreen({super.key});

  @override
  State<AdminAllStudentsScreen> createState() => _AdminAllStudentsScreenState();
}

class _AdminAllStudentsScreenState extends State<AdminAllStudentsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("All Students"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _db.collection("users")
            .where("role", isEqualTo: "student")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          var students = snapshot.data!.docs;

          // GROUP → Department → Class
          Map<String, Map<String, List<QueryDocumentSnapshot>>> deptMap = {};

          for (var s in students) {
            String dept = s["department"] ?? "Unknown";
            String classYear = s["classYear"] ?? "Class N/A";

            deptMap.putIfAbsent(dept, () => {});
            deptMap[dept]!.putIfAbsent(classYear, () => []);
            deptMap[dept]![classYear]!.add(s);
          }

          if (deptMap.isEmpty) {
            return const Center(
              child: Text("No students found", style: TextStyle(color: Colors.white)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(14),
            children: deptMap.entries.map((deptEntry) {
              return Card(
                color: Colors.black,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.white70),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(deptEntry.key,
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
                  children: deptEntry.value.entries.map((classEntry) {
                    return Card(
                      color: Colors.black,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.white38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          classEntry.key,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        children: classEntry.value.map((student) {
                          return ListTile(
                            title: Text(student["name"],
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                                "Admission: ${student['admissionNumber']}",
                                style: const TextStyle(color: Colors.white70)),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
