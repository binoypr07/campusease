class UserModel {
  String uid;
  String name;
  String email;
  String role;
  String department;
  String? classYear;
  int semester;
  String? admissionNumber;
  String? teacherId;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.classYear,
    required this.semester,
    this.admissionNumber,
    this.teacherId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'classYear': classYear,
      'semester': semester,
      'admissionNumber': admissionNumber ?? "",
      'teacherId': teacherId ?? "",
    };
  }
}
