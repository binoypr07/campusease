import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InternalMarksPage extends StatefulWidget {
  final String className;
  const InternalMarksPage({super.key, required this.className});

  @override
  State<InternalMarksPage> createState() => _InternalMarksPageState();
}

class _InternalMarksPageState extends State<InternalMarksPage> {
  // students loaded from users collection filtered by classYear
  List<Map<String, String>> students = [];
  String? selectedStudentId;

  // dynamic list of subject+mark controllers
  final List<Map<String, TextEditingController>> rows = [];

  bool loadingStudents = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _addRow(); // start with one row (like your previous UI)
  }

  @override
  void dispose() {
    for (var r in rows) {
      r['subject']?.dispose();
      r['mark']?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      setState(() => loadingStudents = true);
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classYear', isEqualTo: widget.className)
          .get();

      students = snap.docs.map((d) {
        final map = d.data();
        final name = (map['name'] ?? 'No Name').toString();
        return {'id': d.id, 'name': name};
      }).toList();

      // keep selectedStudentId if present, otherwise first student for convenience
      if (students.isNotEmpty && selectedStudentId == null) {
        selectedStudentId = students.first['id'];
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      students = [];
    } finally {
      setState(() => loadingStudents = false);
    }
  }

  void _addRow() {
    setState(() {
      rows.add({
        'subject': TextEditingController(),
        'mark': TextEditingController(),
      });
    });
  }

  void _removeRow(int idx) {
    if (idx < 0 || idx >= rows.length) return;
    rows[idx]['subject']?.dispose();
    rows[idx]['mark']?.dispose();
    setState(() {
      rows.removeAt(idx);
    });
  }

  Future<void> _saveMarks() async {
    if (selectedStudentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a student')));
      return;
    }

    // build subject->mark map
    final Map<String, int> subjectMarks = {};
    for (var r in rows) {
      final subject = r['subject']!.text.trim();
      final markText = r['mark']!.text.trim();
      if (subject.isEmpty) continue; // skip empty subject rows
      final mark = int.tryParse(markText) ?? 0;
      subjectMarks[subject] = mark;
    }

    if (subjectMarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one subject and mark')),
      );
      return;
    }

    try {
      setState(() => saving = true);

      // Save under internal_marks / <class>_marks / students / <studentId>
      final docRef = FirebaseFirestore.instance
          .collection('internal_marks')
          .doc('${widget.className}_marks')
          .collection('students')
          .doc(selectedStudentId);

      // Merge with existing so teacher can add more subjects later
      await docRef.set(subjectMarks, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marks saved')));
      // optionally clear rows (but keep first empty row)
      for (var r in rows) {
        r['subject']!.clear();
        r['mark']!.clear();
      }
    } catch (e) {
      debugPrint('Error saving marks: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Save failed')));
    } finally {
      setState(() => saving = false);
    }
  }

  Widget _buildRow(int index) {
    final subjectCtrl = rows[index]['subject']!;
    final markCtrl = rows[index]['mark']!;

    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white, width: 1.2),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Subject field
            Expanded(
              flex: 6,
              child: TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            // Mark field
            SizedBox(
              width: 110,
              child: TextField(
                controller: markCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mark',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            // Remove button
            if (rows.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removeRow(index),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Internal Marks'),
        centerTitle: true,
      ),
      body: loadingStudents
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Student dropdown
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Student',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedStudentId,
                          items: students.map((s) {
                            return DropdownMenuItem<String>(
                              value: s['id'],
                              child: Text(s['name'] ?? 'No Name'),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              selectedStudentId = v;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Reload students',
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadStudents,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // dynamic subject-mark rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) => _buildRow(i),
                    ),
                  ),

                  // Add row + Save buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Subject'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saving ? null : _saveMarks,
                          child: saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save All Marks'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
