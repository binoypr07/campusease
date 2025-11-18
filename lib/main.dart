import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ROUTES
import 'views/admin/admin_dashboard.dart';
import 'views/admin/pending_users.dart';
import 'views/teacher/teacher_dashboard.dart';
import 'views/student/student_dashboard.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/check_role.dart';
import 'views/auth/register_student.dart';
import 'views/auth/register_teacher.dart';
import 'views/teacher/assign_class.dart';
import 'views/teacher/attendence_screen.dart';
import 'views/teacher/teacher_profile.dart';
import 'views/teacher/approve_students.dart';
import 'views/student/student_profile.dart';
import 'views/student/student_attendence.dart';
import 'views/student/qr.dart';
import 'views/student/student_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "CampusEase",

      // ---------------------------------------------------
      //                PURE BLACK & WHITE THEME
      // ---------------------------------------------------
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,

        // ---------- APPBAR ----------
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // ---------- TEXT ----------
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        // ---------- TEXTFIELDS ----------
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: Colors.white),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // ---------- BUTTONS ----------
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // white button
            foregroundColor: Colors.black, // black text
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // ---------- CARDS ----------
        cardTheme: CardThemeData(
          color: Colors.black, // pure black cards
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white, width: 1.4),
          ),
        ),
      ),

      // ---------------------------------------------------
      //                      ROUTES
      // ---------------------------------------------------
      routes: {
        '/login': (_) => const LoginScreen(),
        '/checkRole': (_) => const CheckRole(),
        '/registerStudent': (_) => const RegisterStudent(),
        '/registerTeacher': (_) => const RegisterTeacher(),
        '/adminDashboard': (_) => const AdminDashboard(),
        '/teacherDashboard': (_) => const TeacherDashboard(),
        '/studentDashboard': (_) => const StudentDashboard(),
        '/pendingUsers': (_) => const PendingUsersScreen(),
        '/assignClass': (_) => const AssignClassScreen(),
        '/attendance': (_) => const AttendanceScreen(),
        '/teacherProfile': (_) => const TeacherProfileScreen(),
        '/approveStudents': (_) => const TeacherApproveStudents(),
        '/studentProfile': (_) => const StudentProfileScreen(),
        '/studentAttendance': (_) => const StudentAttendanceScreen(),
        '/studentInfo': (_) => const StudentInfoPage(),
      },

      home: FirebaseAuth.instance.currentUser == null
          ? const LoginScreen()
          : const CheckRole(),
    );
  }
}
