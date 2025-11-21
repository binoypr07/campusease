import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _titleC = TextEditingController();
  final TextEditingController _messageC = TextEditingController();

  String? selectedAudience;

  final List<String> audienceOptions = [
    "all",
    "students",
    "teachers",
    "department",
    "class"
  ];

  // departments
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

  // classes
  final List<String> classList = [
    "CS1","CS2","CS3",
    "PHY1","PHY2","PHY3",
    "CHE1","CHE2","CHE3",
    "IC1","IC2","IC3",
    "MAT1","MAT2","MAT3",
    "ZOO1","ZOO2","ZOO3",
    "BOO1","BOO2","BOO3",
    "BCOM1","BCOM2","BCOM3",
    "ECO1","ECO2","ECO3",
    "HIN1","HIN2","HIN3",
    "HIS1","HIS2","HIS3",
    "ENG1","ENG2","ENG3",
    "MAL1","MAL2","MAL3",
  ];

  String? selectedDepartment;
  String? selectedClass;

  bool posting = false;

  Future<void> postAnnouncement() async {
    if (_titleC.text.trim().isEmpty ||
        _messageC.text.trim().isEmpty ||
        selectedAudience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
        ),
      );
      return;
    }

    setState(() => posting = true);

    await _db.collection("announcements").add({
      "title": _titleC.text.trim(),
      "message": _messageC.text.trim(),
      "audienceType": selectedAudience,
      "department": selectedAudience == "department" ? selectedDepartment : null,
      "class": selectedAudience == "class" ? selectedClass : null,
      "createdAt": FieldValue.serverTimestamp(),
    });

    _titleC.clear();
    _messageC.clear();
    selectedAudience = null;
    selectedClass = null;
    selectedDepartment = null;

    setState(() => posting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Announcement Posted!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Announcements")),
      body: Column(
        children: [
          // ---------------------------------------------------
          // CREATE ANNOUNCEMENT PANEL
          // ---------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleC,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Title",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _messageC,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Message",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),

                // AUDIENCE DROPDOWN
                DropdownButtonFormField<String>(
                  value: selectedAudience,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Audience",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  items: audienceOptions
                      .map((a) =>
                          DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedAudience = v;
                      selectedDepartment = null;
                      selectedClass = null;
                    });
                  },
                ),

                // IF department chosen → show dept dropdown
                if (selectedAudience == "department")
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      items: departments
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: "Select Department",
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) => setState(() {
                        selectedDepartment = v;
                      }),
                    ),
                  ),

                // IF class chosen → show class dropdown
                if (selectedAudience == "class")
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DropdownButtonFormField<String>(
                      value: selectedClass,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      items: classList
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: "Select Class",
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) => setState(() {
                        selectedClass = v;
                      }),
                    ),
                  ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: posting ? null : postAnnouncement,
                    child: posting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Post Announcement"),
                  ),
                )
              ],
            ),
          ),

          const Divider(color: Colors.white70),

          // ---------------------------------------------------
          // ALL ANNOUNCEMENTS LIST
          // ---------------------------------------------------
          Expanded(
            child: StreamBuilder(
              stream: _db
                  .collection("announcements")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, s) {
                if (!s.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                var docs = s.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No announcements yet",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var a = docs[index].data();

                    return Card(
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                            color: Colors.white70, width: 1.2),
                      ),
                      child: ListTile(
                        title: Text(
                          a["title"] ?? "",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a["message"] ?? "",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Audience: ${a["audienceType"]}",
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
