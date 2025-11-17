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
  String? teacherDept;
  String? assignedClass;

  // All available classes
  final List<String> allClasses = [
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

  List<String> freeClasses = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTeacherDetails();
  }

  // --------------------------------------------------------
  // LOAD TEACHER DETAILS + EXISTING CLASS ASSIGNMENT
  // --------------------------------------------------------
  Future<void> loadTeacherDetails() async {
    teacherUid = FirebaseAuth.instance.currentUser!.uid;

    var doc = await FirebaseFirestore.instance.collection("users").doc(teacherUid).get();

    teacherDept = doc["department"];
    assignedClass = doc["assignedClass"];

    await loadFreeClasses();

    setState(() {
      loading = false;
    });
  }

  // --------------------------------------------------------
  // FIND WHICH CLASSES ARE ALREADY TAKEN BY OTHER TEACHERS
  // --------------------------------------------------------
  Future<void> loadFreeClasses() async {
    var allTeacherDocs = await FirebaseFirestore.instance.collection("users")
        .where("role", isEqualTo: "teacher")
        .get();

    // Collect assigned classes
    List<String> taken = [];
    for (var t in allTeacherDocs.docs) {
      if (t["assignedClass"] != null && t["assignedClass"] != "") {
        taken.add(t["assignedClass"]);
      }
    }

    // available = allClasses - taken
    freeClasses = allClasses.where((cls) => !taken.contains(cls)).toList();
  }

  // --------------------------------------------------------
  // ASSIGN CLASS PERMANENTLY (NO CHANGES AFTER)
  // --------------------------------------------------------
  Future<void> assignClass(String cls) async {
    await FirebaseFirestore.instance.collection("users").doc(teacherUid).update({
      "assignedClass": cls,
    });

    Get.snackbar(
      "Assigned!",
      "Class $cls assigned successfully",
      backgroundColor: Colors.black,
      colorText: Colors.white,
    );

    setState(() {
      assignedClass = cls;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // --------------------------------------------------------
    // IF TEACHER ALREADY HAS A CLASS → NO MORE CHANGES ALLOWED
    // --------------------------------------------------------
    if (assignedClass != null && assignedClass!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Assign Class"),
          centerTitle: true,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "You already have a class assigned:\n\n$assignedClass",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // SHOW ONLY FREE CLASSES
    // --------------------------------------------------------
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Class"),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a Class (only free classes shown)",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Choose Class",
              ),
              items: freeClasses.map(
                (cls) => DropdownMenuItem(
                  value: cls,
                  child: Text(cls),
                ),
              ).toList(),
              onChanged: (cls) {
                assignClass(cls!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
