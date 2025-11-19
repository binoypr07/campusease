// lib/views/announcements/create_announcement.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final TextEditingController titleCtl = TextEditingController();
  final TextEditingController bodyCtl = TextEditingController();

  String role = '';
  String department = '';
  String? target = 'ALL';
  String? targetValue; // for DEPARTMENT or CLASS

  final List<String> targetsAdmin = [
    'ALL',
    'ALL_STUDENTS',
    'ALL_TEACHERS',
    'DEPARTMENT',
    'CLASS'
  ];

  final List<String> classList = [
    "CS1","CS2","CS3","PHY1","PHY2","PHY3","CHE1","CHE2","CHE3","IC1","IC2","IC3",
    "MAT1","MAT2","MAT3","ZOO1","ZOO2","ZOO3","BOO1","BOO2","BOO3","BCOM1","BCOM2","BCOM3",
    "ECO1","ECO2","ECO3","HIN1","HIN2","HIN3","HIS1","HIS2","HIS3","ENG1","ENG2","ENG3","MAL1","MAL2","MAL3"
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

  bool loading = false;
  String teacherAssignedClass = '';
  String teacherDepartment = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) {
      // safety: user may be admin in separate collection - check pending? but generally exists
      role = 'student';
    } else {
      var d = doc.data()!;
      role = (d['role'] ?? '').toString();
      teacherDepartment = (d['department'] ?? '').toString();
      teacherAssignedClass = (d['assignedClass'] ?? '').toString();
    }

    // if teacher default choices
    if (role == 'teacher') {
      setState(() {
        target = 'DEPARTMENT';
        targetValue = teacherDepartment;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> sendAnnouncement() async {
    if (titleCtl.text.trim().isEmpty || bodyCtl.text.trim().isEmpty) {
      Get.snackbar('Missing', 'Title and message required',
          backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
      return;
    }

    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final senderDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final senderDept = senderDoc.exists ? (senderDoc.data()!['department'] ?? '') : '';
    final senderRole = senderDoc.exists ? (senderDoc.data()!['role'] ?? 'admin') : 'admin';

    final Map<String, dynamic> ann = {
      'title': titleCtl.text.trim(),
      'message': bodyCtl.text.trim(),
      'senderUid': uid,
      'senderRole': senderRole,
      'senderDepartment': senderDept,
      'target': target,
      'targetValue': targetValue ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    };

    // store announcement
    await FirebaseFirestore.instance.collection('announcements').add(ann);

    setState(() => loading = false);

    Get.snackbar('Sent', 'Announcement posted', backgroundColor: Colors.black, colorText: Colors.white);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Create Announcement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleCtl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
                controller: bodyCtl,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 5),
            const SizedBox(height: 16),

            // Target selection
            if (isAdmin) ...[
              DropdownButtonFormField<String>(
                value: target,
                decoration: const InputDecoration(labelText: 'Target'),
                items: targetsAdmin.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  setState(() {
                    target = v;
                    targetValue = null;
                  });
                },
              ),
            ] else ...[
              // teacher - show only department and assigned class options
              const SizedBox(height: 6),
              Text('You are a teacher. You can send to your department or assigned class.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        target = 'DEPARTMENT';
                        targetValue = teacherDepartment;
                      });
                    },
                    child: const Text('Department'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: teacherAssignedClass.isEmpty ? null : () {
                      setState(() {
                        target = 'CLASS';
                        targetValue = teacherAssignedClass;
                      });
                    },
                    child: const Text('Assigned Class'),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 12),

            // if target needs extra value (admin selecting department or class)
            if ((target == 'DEPARTMENT') && isAdmin)
              DropdownButtonFormField<String>(
                value: targetValue,
                decoration: const InputDecoration(labelText: 'Select Department'),
                items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => targetValue = v),
              ),

            if ((target == 'CLASS') && isAdmin)
              DropdownButtonFormField<String>(
                value: targetValue,
                decoration: const InputDecoration(labelText: 'Select Class'),
                items: classList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => targetValue = v),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : sendAnnouncement,
                child: loading ? const CircularProgressIndicator(color: Colors.black) : const Text('Send Announcement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
