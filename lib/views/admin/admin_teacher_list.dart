import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAllTeachersScreen extends StatefulWidget {
  const AdminAllTeachersScreen({super.key});

  @override
  State<AdminAllTeachersScreen> createState() => _AdminAllTeachersScreenState();
}

class _AdminAllTeachersScreenState extends State<AdminAllTeachersScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("All Teachers"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _db.collection("users")
            .where("role", isEqualTo: "teacher")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          var teachers = snapshot.data!.docs;

          // GROUP BY DEPARTMENT
          Map<String, List<QueryDocumentSnapshot>> deptMap = {};

          for (var t in teachers) {
            String dept = t["department"] ?? "Unknown";
            deptMap.putIfAbsent(dept, () => []);
            deptMap[dept]!.add(t);
          }

          if (deptMap.isEmpty) {
            return const Center(
              child: Text("No teachers found", style: TextStyle(color: Colors.white)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(14),
            children: deptMap.entries.map((entry) {
              return Card(
                color: Colors.black,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.white70),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(entry.key,
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
                  children: entry.value.map((teacher) {
                    return ListTile(
                      title: Text(teacher["name"], style: const TextStyle(color: Colors.white)),
                      subtitle: Text("ID: ${teacher['teacherId']}",
                          style: const TextStyle(color: Colors.white70)),
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
