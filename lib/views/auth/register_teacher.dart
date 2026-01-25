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

  final Map<String, List<String>> departmentSubjects = {
    "Computer Science": [
      "DBMS",
      "OS",
      "CN",
      "Python",
      "Java",
      "Android",
      "C",
      "C++",
      "Javascript",
    ],
    "Physics": [
      "Mechanics",
      "Electromagnetism",
      "Optics",
      "Thermodynamics",
      "Quantam Mechanics",
    ],
    "Chemistry": [
      "Inorganicchemistry",
      "Organicchemistry",
      "Environmentalchemistry",
      "Polymerchemistry",
      "Biochemistry",
    ],
    "Maths": [
      "Calculas",
      "Algebra",
      "Differentialequations",
      "Geometry",
      "Linearalgebra",
    ],
    "English": ["Language skills", "Gramer", "Applied english", "literature"],
    "Hindi": ["Language skills", "Gramer", "Applied hindi", "literature"],
    "Malayalam": [
      "History of Malayalam litarature",
      "Malayalam poetry",
      "Malayalam drama&film",
    ],
    "History": [
      "Modern world History",
      "Indian history",
      "Histrography",
      "Methodology",
      "History of human rights",
    ],
    "Economics": [
      "Macroeconomics",
      "Indianeconomics",
      "fiscaleconomics",
      "Mathamatical Economics",
    ],
    "Commerce": [
      "Financial Accounting",
      "Bussinus Law",
      "Bussinus regulation",
      "Coast Accounting",
    ],
    "Zoology": [
      "Animaldiversity",
      "Physiology",
      "Genetics",
      "Ecology",
      "Entomology",
    ],
    "Botany": [
      "Phycology",
      "Bryology",
      "Microbiology",
      "Ecology",
      "Plant physilogy",
    ],
  };

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

  FirebaseAuthService authService = FirebaseAuthService();
  bool loading = false;

  // -------------------------------
  // CHECK ALL REQUIRED FIELDS
  // -------------------------------
  bool get isFormValid {
    return name.text.trim().isNotEmpty &&
        email.text.trim().isNotEmpty &&
        password.text.trim().isNotEmpty &&
        teacherId.text.trim().isNotEmpty &&
        selectedDept != null &&
        selectedSubjects.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Teacher Registration"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // -------------------
          // BACKGROUND IMAGE
          // -------------------
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                "assets/images/background.jpeg",
                fit: BoxFit.cover,
              ),
            ),
          ),

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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                const Text("Email", style: TextStyle(color: Colors.white70)),
                TextField(
                  controller: email,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                const Text("Password", style: TextStyle(color: Colors.white70)),
                TextField(
                  controller: password,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Teacher ID",
                  style: TextStyle(color: Colors.white70),
                ),
                TextField(
                  controller: teacherId,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(),
                  onChanged: (_) => setState(() {}),
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
                      selectedSubjects.clear();
                    });
                  },
                ),
                const SizedBox(height: 20),

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
                  children: selectedDept == null
                      ? []
                      : departmentSubjects[selectedDept]!.map((sub) {
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

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!isFormValid || loading)
                        ? null
                        : registerTeacher,
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
        ],
      ),
    );
  }

  Future<void> registerTeacher() async {
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
