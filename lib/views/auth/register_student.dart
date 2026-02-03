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

  final Map<String, List<String>> departmentClasses = {
    "Computer Science": ["CS1", "CS2", "CS3", "CS4"],
    "Physics": ["PHY1", "PHY2", "PHY3", "PHY4"],
    "Chemistry": ["CHE1", "CHE2", "CHE3", "CHE4"],
    "Maths": ["MAT1", "MAT2", "MAT3", "MAT4"],
    "Commerce": ["BCOM1", "BCOM2", "BCOM3", "BCOM4"],
    "Economics": ["ECO1", "ECO2", "ECO3", "ECO4"],
    "Hindi": ["HIN1", "HIN2", "HIN3", "HIN4"],
    "History": ["HIS1", "HIS2", "HIS3", "HIS4"],
    "English": ["ENG1", "ENG2", "ENG3", "ENG4"],
    "Malayalam": ["MAL1", "MAL2", "MAL3", "MAL4"],
    "Zoology": ["ZOO1", "ZOO2", "ZOO3", "ZOO4"],
    "Botany": ["BOO1", "BOO2", "BOO3", "BOO4"],
  };

  bool loading = false;

  /// FORM VALIDATION 
  bool get isFormValid =>
      name.text.trim().isNotEmpty &&
      email.text.trim().isNotEmpty &&
      password.text.trim().isNotEmpty &&
      phone.text.trim().isNotEmpty &&
      admissionNumber.text.trim().isNotEmpty &&
      selectedDept != null &&
      selectedClass != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Student Registration"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ///  BACKGROUND IMAGE 
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/background.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          ///  MAIN CONTENT
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Full Name",
                  style: TextStyle(color: Colors.white70),
                ),
                TextField(
                  controller: name,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 20),

                const Text("Email", style: TextStyle(color: Colors.white70)),
                TextField(
                  controller: email,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 20),

                const Text("Password", style: TextStyle(color: Colors.white70)),
                TextField(
                  controller: password,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 20),

                const Text("Phone", style: TextStyle(color: Colors.white70)),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Admission Number (Required)",
                  style: TextStyle(color: Colors.white70),
                ),
                TextField(
                  controller: admissionNumber,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Department",
                  style: TextStyle(color: Colors.white70),
                ),
                DropdownButtonFormField<String>(
                  value: selectedDept,
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
                  onChanged: (value) {
                    setState(() {
                      selectedDept = value;
                      selectedClass = null;
                    });
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  "Select Class",
                  style: TextStyle(color: Colors.white70),
                ),
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                  items: selectedDept == null
                      ? []
                      : departmentClasses[selectedDept]!
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
                  onChanged: (value) {
                    setState(() => selectedClass = value);
                  },
                ),
                const SizedBox(height: 40),

                /// BUTTON DISABLED UNTIL ALL FIELDS FILLED
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!isFormValid || loading)
                        ? null
                        : registerStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "Register",
                            style: TextStyle(fontSize: 17),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> registerStudent() async {
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
