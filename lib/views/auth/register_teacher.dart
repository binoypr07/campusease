import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../models/user_model.dart';

class RegisterTeacher extends StatefulWidget {
  const RegisterTeacher({super.key});

  @override
  State<RegisterTeacher> createState() => _RegisterTeacherState();
}

class _RegisterTeacherState extends State<RegisterTeacher> {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController teacherId = TextEditingController();

  String? selectedDept;

  List<String> selectedSubjects = [];
  List<String> allSubjects = [
    "DBMS",
    "OS",
    "CN",
    "Python",
    "Maths",
    "Physics",
    "Chemistry",
    "English",
    "Hindi",
    "Malayalam",
  ];

  final List<String> departments = [
    "Computer Science",
    "Physics",
    "Chemistry",
    "Maths",
    "Malayalam",
    "Hindi",
    "English",
    "History",
    "Economics",
    "Commerce",
    "Zoology",
    "Botany"
  ];

  FirebaseAuthService authService = FirebaseAuthService();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Teacher Registration"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------- NAME ----------
            const Text("Full Name", style: TextStyle(color: Colors.white70)),
            TextField(
              controller: name,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),

            // ---------- EMAIL ----------
            const Text("Email", style: TextStyle(color: Colors.white70)),
            TextField(
              controller: email,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),

            // ---------- TEACHER ID ----------
            const Text("Teacher ID", style: TextStyle(color: Colors.white70)),
            TextField(
              controller: teacherId,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),

            // ---------- DEPARTMENT ----------
            const Text("Department", style: TextStyle(color: Colors.white70)),
            DropdownButtonFormField<String>(
              initialValue: selectedDept,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
              items: departments
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedDept = value),
            ),
            const SizedBox(height: 20),

            // ---------- SUBJECTS ----------
            const Text(
              "Select Subjects (Multiple)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: allSubjects.map((sub) {
                bool isSelected = selectedSubjects.contains(sub);
                return ChoiceChip(
                  label: Text(
                    sub,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white),
                  onSelected: (selected) {
                    setState(() {
                      if (isSelected) {
                        selectedSubjects.remove(sub);
                      } else {
                        selectedSubjects.add(sub);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // ---------- PASSWORD ----------
            const Text("Password", style: TextStyle(color: Colors.white70)),
            TextField(
              controller: password,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 40),

            // ---------- REGISTER BUTTON ----------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : registerTeacher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> registerTeacher() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.trim().isEmpty ||
        teacherId.text.trim().isEmpty ||
        selectedDept == null ||
        selectedSubjects.isEmpty) {
      Get.snackbar(
        "Missing Fields",
        "Please fill all fields and select at least one subject.",
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => loading = true);

    UserModel user = UserModel(
      uid: "",
      name: name.text.trim(),
      email: email.text.trim(),
      role: "teacher",
      department: selectedDept!,
      classYear: "",
      semester: 0,
      teacherId: teacherId.text.trim(),
      admissionNumber: "",
    );

    Map<String, dynamic> extraData = {
      "subjects": selectedSubjects,
      "assignedClass": null,
    };

    var created = await authService.registerUser(
      email.text.trim(),
      password.text.trim(),
      user.toMap(),
    );

    if (created != null) {
      await authService.addExtraTeacherData(created.uid, extraData);

      setState(() => loading = false);

      Get.snackbar(
        "Pending Approval",
        "Please wait for admin approval.",
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );

      Get.offAllNamed('/login');
    } else {
      setState(() => loading = false);

      Get.snackbar(
        "Failed",
        "Registration failed. Try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
