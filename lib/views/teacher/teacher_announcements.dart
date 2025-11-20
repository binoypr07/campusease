// lib/views/teacher/teacher_announcements.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TeacherAnnouncementsScreen extends StatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  State<TeacherAnnouncementsScreen> createState() =>
      _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState
    extends State<TeacherAnnouncementsScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();

  String? teacherDepartment;
  String? assignedClass;
  String uid = FirebaseAuth.instance.currentUser!.uid;
  bool loadingTeacher = true;
  bool creating = false;

  // Target options
  final List<String> _targets = ['All', 'Department', 'Assigned Class'];
  String _selectedTarget = 'All';

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        setState(() {
          teacherDepartment = (doc.data() ?? {})['department']?.toString() ?? '';
          assignedClass = (doc.data() ?? {})['assignedClass']?.toString() ?? '';
        });
      }
    } catch (e) {
      print("Load teacher info error: $e");
    } finally {
      setState(() {
        loadingTeacher = false;
      });
    }
  }

  bool _appliesToTeacher(Map<String, dynamic> ann) {
    // ann fields: targetType ('all'|'department'|'class'), targetValue (string), senderId
    String targetType = (ann['targetType'] ?? 'all').toString();
    String targetValue = (ann['targetValue'] ?? '').toString();
    String senderId = (ann['senderId'] ?? '').toString();

    if (senderId == uid) return true; // teacher always sees own posts
    if (targetType == 'all') return true;

    if (targetType == 'department' && teacherDepartment != null) {
      return targetValue == teacherDepartment;
    }

    if (targetType == 'class' && assignedClass != null) {
      return targetValue == assignedClass;
    }

    return false;
  }

  Future<void> _createAnnouncement() async {
    final String title = _titleCtrl.text.trim();
    final String body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      Get.snackbar("Missing", "Please enter title and message",
          backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
      return;
    }

    // decide targetType/value
    String targetType = 'all';
    String targetValue = '';

    if (_selectedTarget == 'All') {
      targetType = 'all';
      targetValue = '';
    } else if (_selectedTarget == 'Department') {
      if (teacherDepartment == null || teacherDepartment!.isEmpty) {
        Get.snackbar("Error", "Your department is not set",
            backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
        return;
      }
      targetType = 'department';
      targetValue = teacherDepartment!;
    } else if (_selectedTarget == 'Assigned Class') {
      if (assignedClass == null || assignedClass!.isEmpty) {
        Get.snackbar("Error", "No assigned class found",
            backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
        return;
      }
      targetType = 'class';
      targetValue = assignedClass!;
    }

    setState(() => creating = true);

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'body': body,
        'senderId': uid,
        'senderRole': 'teacher',
        'senderName': FirebaseAuth.instance.currentUser!.email ?? '',
        'targetType': targetType, // all / department / class
        'targetValue': targetValue,
        'department': teacherDepartment ?? '',
        'class': assignedClass ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.snackbar("Success", "Announcement created",
          backgroundColor: Colors.black, colorText: Colors.white);

      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _selectedTarget = 'All');
    } catch (e) {
      print("Create announcement error: $e");
      Get.snackbar("Error", "Failed to create announcement",
          backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
    } finally {
      setState(() => creating = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingTeacher) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Announcements"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // CREATE CARD
            Card(
              color: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Title",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bodyCtrl,
                      style: const TextStyle(color: Colors.white),
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: "Message",
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("Target:",
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          dropdownColor: Colors.black,
                          value: _selectedTarget,
                          items: _targets
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectedTarget = v);
                          },
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        if (_selectedTarget == 'Department' && teacherDepartment != null)
                          Text("Dept: $teacherDepartment",
                              style: const TextStyle(color: Colors.white70)),
                        if (_selectedTarget == 'Assigned Class' && assignedClass != null)
                          Text("Class: $assignedClass",
                              style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: creating ? null : _createAnnouncement,
                        child: creating
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text("Create Announcement"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // LIST TITLE
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Announcements",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ANNOUNCEMENTS LIST (stream all, filter client-side)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('announcements')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs;

                  // Map -> filter by _appliesToTeacher
                  var filtered = docs.where((d) {
                    var data = d.data() as Map<String, dynamic>? ?? {};
                    return _appliesToTeacher(data);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        "No announcements yet.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      var doc = filtered[index];
                      var data = doc.data() as Map<String, dynamic>;
                      Timestamp? ts = data['timestamp'] as Timestamp?;
                      String date = ts != null
                          ? DateFormat('yyyy-MM-dd – kk:mm').format(ts.toDate())
                          : 'Just now';

                      String title = data['title'] ?? '';
                      String body = data['body'] ?? '';
                      String senderName = data['senderName'] ?? 'Unknown';
                      String targetType = (data['targetType'] ?? 'all').toString();
                      String targetValue = (data['targetValue'] ?? '').toString();

                      String targetLabel = 'All';
                      if (targetType == 'department') targetLabel = 'Dept: $targetValue';
                      if (targetType == 'class') targetLabel = 'Class: $targetValue';

                      return Card(
                        color: Colors.black,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.white, width: 1.0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(title,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(body, style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text("By: $senderName",
                                      style: const TextStyle(color: Colors.white54)),
                                  const SizedBox(width: 12),
                                  Text(targetLabel,
                                      style: const TextStyle(color: Colors.white54)),
                                  const Spacer(),
                                  Text(date, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            // optional: open detail or allow edit/delete if sender==uid
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
