import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AssignClassScreen extends StatefulWidget {
  const AssignClassScreen({super.key});

  @override
  State<AssignClassScreen> createState() => _AssignClassScreenState();
}

class _AssignClassScreenState extends State<AssignClassScreen> {
  String? teacherUid;
  String? teacherName;
  String? assignedClass;

  final List<String> classList = [
   "CS1","CS2","CS3","CS4",
   "PHY1","PHY2","PHY3","PHY4",
   "CHE1","CHE2","CHE3","CHE4",
   "IC1","IC2","IC3","IC4",
   "MAT1","MAT2","MAT3","MAT4",
   "ZOO1","ZOO2","ZOO3","ZOO4",
   "BOO1","BOO2","BOO3","BOO4",
   "BCOM1","BCOM2","BCOM3","BCOM4",
   "ECO1","ECO2","ECO3","ECO4",
   "HIN1","HIN2","HIN3","HIN4",
   "HIS1","HIS2","HIS3","HIS3",
   "ENG1","ENG2","ENG3","ENG4",
   "MAL1","MAL2","MAL3","MAL4",
  ];

  Map<String, dynamic> occupiedClasses = {};

  @override
  void initState() {
    super.initState();
    loadTeacher();
    loadOccupiedClasses();
  }

  Future<void> loadTeacher() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();

    setState(() {
      teacherUid = uid;
      teacherName = doc["name"];
      assignedClass = doc["assignedClass"];
    });
  }

  Future<void> loadOccupiedClasses() async {
    var snap =
        await FirebaseFirestore.instance.collection("classAssignments").get();

    Map<String, dynamic> temp = {};
    for (var doc in snap.docs) {
      temp[doc.id] = doc.data()["teacherUid"];
    }

    setState(() => occupiedClasses = temp);
  }

  Future<void> assignClass(String className) async {
    // Prevent overwrite if already taken
    if (occupiedClasses[className] != null) {
      Get.snackbar(
        "Class Occupied",
        "$className is already assigned to another teacher.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Save in classAssignments
    await FirebaseFirestore.instance
        .collection("classAssignments")
        .doc(className)
        .set({
      "teacherUid": teacherUid,
      "teacherName": teacherName,
    });

    // Save in teacher profile
    await FirebaseFirestore.instance
        .collection("users")
        .doc(teacherUid)
        .update({
      "assignedClass": className,
    });

    Get.snackbar(
      "Assigned",
      "Class $className assigned successfully!",
      backgroundColor: Colors.black,
      colorText: Colors.white,
    );

    loadOccupiedClasses();
    loadTeacher();
  }

  @override
  Widget build(BuildContext context) {
    if (teacherUid == null || occupiedClasses.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Teacher already has a class → lock screen
    if (assignedClass != null && assignedClass!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Assign Class")),
        body: Center(
          child: Text(
            "You are already assigned to class: $assignedClass\n\nOnly admin can change it.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Assign Class")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classList.length,
        itemBuilder: (context, index) {
          String className = classList[index];
          bool isTaken = occupiedClasses[className] != null;

          return Card(
            child: ListTile(
              title: Text(
                className,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              subtitle: isTaken
                  ? Text(
                      "Already assigned",
                      style: TextStyle(color: Colors.red.shade300),
                    )
                  : const Text(
                      "Available",
                      style: TextStyle(color: Colors.white),
                    ),
              trailing: isTaken
                  ? const Icon(Icons.lock, color: Colors.red)
                  : const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: isTaken
                  ? null
                  : () {
                      assignClass(className);
                    },
            ),
          );
        },
      ),
    );
  }
}
