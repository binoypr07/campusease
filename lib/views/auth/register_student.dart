import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../models/user_model.dart';
import 'package:flutter/services.dart';

class RegisterStudent extends StatefulWidget {
  const RegisterStudent({super.key});

  @override
  State<RegisterStudent> createState() => _RegisterStudentState();
}

class _RegisterStudentState extends State<RegisterStudent> {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController admissionNumber = TextEditingController();

  String? selectedDept;
  String? selectedClass;

  FirebaseAuthService authService = FirebaseAuthService();

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
    "Botany",
  ];

  final List<String> classList = [
    "CS1",
    "CS2",
    "CS3",
    "CS4",
    "PHY1",
    "PHY2",
    "PHY3",
    "PHY4",
    "CHE1",
    "CHE2",
    "CHE3",
    "CHE4",
    "IC1",
    "IC2",
    "IC3",
    "IC4",
    "MAT1",
    "MAT2",
    "MAT3",
    "MAT4",
    "ZOO1",
    "ZOO2",
    "ZOO3",
    "ZOO4",
    "BOO1",
    "BOO2",
    "BOO3",
    "BOO4",
    "BCOM1",
    "BCOM2",
    "BCOM3",
    "BCOM4",
    "ECO1",
    "ECO2",
    "ECO3",
    "ECO4",
    "HIN1",
    "HIN2",
    "HIN3",
    "HIN4",
    "HIS1",
    "HIS2",
    "HIS3",
    "HIS3",
    "ENG1",
    "ENG2",
    "ENG3",
    "ENG4",
    "MAL1",
    "MAL2",
    "MAL3",
    "MAL4",
  ];

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Student Registration"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------- NAME -------------------
            const Text("Full Name", style: TextStyle(color: Colors.white70)),
            TextField(
              controller: name,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),

            // ------------------- EMAIL -------------------
            const Text("Email", style: TextStyle(color: Colors.white70)),
            TextField(
              controller: email,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),

            // ------------------- PHONENUMBER -------------------
            const Text("Phone", style: TextStyle(color: Colors.white70)),
            TextField(
              controller: phone,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // only allow digits
                LengthLimitingTextInputFormatter(10), // max 10 digits
              ],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),

            // ------------------- ADMISSION NUMBER -------------------
            const Text(
              "Admission Number (Required)",
              style: TextStyle(color: Colors.white70),
            ),
            TextField(
              controller: admissionNumber,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),

            // ------------------- DEPARTMENT -------------------
            const Text("Department", style: TextStyle(color: Colors.white70)),
            DropdownButtonFormField<String>(
              initialValue: selectedDept,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
              items: departments
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        d,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedDept = value),
            ),
            const SizedBox(height: 20),

            // ------------------- CLASS -------------------
            const Text("Select Class", style: TextStyle(color: Colors.white70)),
            DropdownButtonFormField<String>(
              initialValue: selectedClass,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
              items: classList
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedClass = value),
            ),
            const SizedBox(height: 20),

            // ------------------- PASSWORD -------------------
            const Text("Password", style: TextStyle(color: Colors.white70)),
            TextField(
              controller: password,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 40),

            // ------------------- REGISTER BUTTON -------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : registerStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Register", style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> registerStudent() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.trim().isEmpty ||
        admissionNumber.text.trim().isEmpty ||
        selectedDept == null ||
        selectedClass == null) {
      Get.snackbar(
        "Missing Fields",
        "Please fill all fields before continuing.",
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
      role: "student",
      department: selectedDept!,
      classYear: selectedClass!,
      semester: 1,
      admissionNumber: admissionNumber.text.trim(),
      teacherId: "",
    );

    var created = await authService.registerUser(
      email.text.trim(),
      password.text.trim(),
      user.toMap(),
    );

    setState(() => loading = false);

    if (created != null) {
      Get.snackbar(
        "Pending Approval",
        "Please wait for admin/teacher approval.",
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
      Get.offAllNamed('/login');
    } else {
      Get.snackbar(
        "Failed",
        "Registration failed. Try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
