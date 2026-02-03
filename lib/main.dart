import 'package:campusease/views/splash/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_handler.dart';

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
import 'views/student/student_info.dart';
import 'views/admin/admin_announcements.dart';
import 'views/teacher/teacher_announcements.dart';
import 'views/student/student_announcements.dart';
import 'views/admin/admin_students_list.dart';
import 'views/admin/admin_teacher_list.dart';
import 'views/admin/admin_attendance_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background Notification: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await NotificationHandler.init();
    NotificationHandler.listenForeground();

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          msg.notification?.title ?? "Notification",
          msg.notification?.body ?? "",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.black,
          colorText: Colors.white,
        );
      });
    });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "CampusEase",
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,

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

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

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

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        cardTheme: CardThemeData(
          color: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white, width: 1.4),
          ),
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),

      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/checkRole', page: () => const CheckRole()),

        GetPage(name: '/registerStudent', page: () => const RegisterStudent()),
        GetPage(name: '/registerTeacher', page: () => const RegisterTeacher()),

        GetPage(name: '/adminDashboard', page: () => const AdminDashboard()),
        GetPage(name: '/pendingUsers', page: () => const PendingUsersScreen()),
        GetPage(
          name: '/adminAnnouncements',
          page: () => const AdminAnnouncementsScreen(),
        ),
        GetPage(
          name: '/adminTeachers',
          page: () => const AdminAllTeachersScreen(),
        ),
        GetPage(
          name: '/adminStudents',
          page: () => const AdminAllStudentsScreen(),
        ),

        GetPage(
          name: '/teacherDashboard',
          page: () => const TeacherDashboard(),
        ),
        GetPage(name: '/assignClass', page: () => const AssignClassScreen()),
        GetPage(name: '/attendance', page: () => const AttendanceScreen()),
        GetPage(
          name: '/teacherProfile',
          page: () => const TeacherProfileScreen(),
        ),
        GetPage(
          name: '/approveStudents',
          page: () => const TeacherApproveStudents(),
        ),
        GetPage(
          name: '/teacherAnnouncements',
          page: () => const TeacherAnnouncementsScreen(),
        ),

        GetPage(
          name: '/studentDashboard',
          page: () => const StudentDashboard(),
        ),
        GetPage(
          name: '/studentProfile',
          page: () => const StudentProfileScreen(),
        ),
        GetPage(
          name: '/studentAttendance',
          page: () => StudentAttendanceScreen(),
        ),
        GetPage(name: '/studentInfo', page: () => const StudentInfoPage()),
        GetPage(
          name: '/studentAnnouncements',
          page: () => const StudentAnnouncementsScreen(),
        ),
        GetPage(
          name: '/adminAttendance',
          page: () => const AdminAttendanceScreen(),
        ),
        GetPage(name: '/', page: () => const SplashScreen()),
      ],

      home: const SplashScreen(),
    );
  }
}
