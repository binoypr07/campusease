import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'time_table_entry.dart';

const _bg = Color(0xFF121212);
const _surface = Color(0xFF1E1E1E);
const _surface2 = Color(0xFF2A2A2A);
const _blue = Colors.blue;
const _textPri = Colors.white;
const _textSec = Color(0xFF9E9E9E);

class EditableTimetablePage extends StatefulWidget {
  final String className;
  const EditableTimetablePage({super.key, required this.className});

  @override
  State<EditableTimetablePage> createState() => _EditableTimetablePageState();
}

class _EditableTimetablePageState extends State<EditableTimetablePage>
    with SingleTickerProviderStateMixin {
  static const List<String> days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];
  static const List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  late TabController _tabController;
  Map<String, List<TimetableEntry>> allEntries = {for (final d in days) d: []};
  bool loading = true;
  bool _overrideWeekend =
      false; // true when teacher taps "Edit Monday" on weekend

  // null on weekends
  int? get todayIndex {
    final weekday = DateTime.now().weekday;
    if (weekday >= 1 && weekday <= 5) return weekday - 1;
    return null;
  }

  bool get isWeekend => todayIndex == null && !_overrideWeekend;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: days.length,
      vsync: this,
      initialIndex: todayIndex ?? 0,
    );
    loadTimetable();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadTimetable() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('timetables')
          .doc(widget.className)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        for (final day in days) {
          List raw = data[day] ?? [];
          allEntries[day] = raw
              .map(
                (e) => TimetableEntry(
                  subject: e['subject'] ?? '',
                  time: e['time'] ?? '',
                  teacher: e['teacher'] ?? '',
                  room: e['room'] ?? '',
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error loading timetable: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveTimetable() async {
    try {
      final Map<String, dynamic> data = {};
      for (final day in days) {
        data[day] = allEntries[day]!
            .map(
              (e) => {
                'subject': e.subject,
                'time': e.time,
                'teacher': e.teacher,
                'room': e.room,
              },
            )
            .toList();
      }

      await FirebaseFirestore.instance
          .collection('timetables')
          .doc(widget.className)
          .set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _surface2,
          content: Text('Timetable saved ✅', style: TextStyle(color: _textPri)),
        ),
      );
    } catch (e) {
      debugPrint("Error saving: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _surface2,
          content: Text('Failed to save ❌', style: TextStyle(color: _textPri)),
        ),
      );
    }
  }

  void editEntry(String day, int index) {
    final entry = allEntries[day]![index];
    final subjectController = TextEditingController(text: entry.subject);
    final timeController = TextEditingController(text: entry.time);
    final teacherController = TextEditingController(text: entry.teacher);
    final roomController = TextEditingController(text: entry.room);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Edit Entry",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPri,
                ),
              ),
              const SizedBox(height: 20),
              _field(subjectController, 'Subject', Icons.book_outlined),
              const SizedBox(height: 12),
              _field(
                timeController,
                'Time (e.g. 9:00 - 10:00 AM)',
                Icons.access_time_rounded,
              ),
              const SizedBox(height: 12),
              _field(
                teacherController,
                'Teacher',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              _field(roomController, 'Room', Icons.meeting_room_outlined),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: _textSec),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        allEntries[day]![index] = TimetableEntry(
                          subject: subjectController.text,
                          time: timeController.text,
                          teacher: teacherController.text,
                          room: roomController.text,
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _textPri),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSec),
        prefixIcon: Icon(icon, color: _textSec, size: 20),
        filled: true,
        fillColor: _surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDayTab(String day) {
    final entries = allEntries[day]!;

    return Stack(
      children: [
        entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        size: 52,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "No entries yet",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textPri,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tap + to add a class",
                      style: TextStyle(fontSize: 13, color: _textSec),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // Period sidebar
                          Container(
                            width: 56,
                            decoration: const BoxDecoration(
                              color: _surface2,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _blue,
                                  ),
                                ),
                                const Text(
                                  "Period",
                                  style: TextStyle(fontSize: 10, color: _blue),
                                ),
                              ],
                            ),
                          ),
                          // Blue accent strip
                          Container(width: 3, color: _blue),
                          // Content — tappable to edit
                          Expanded(
                            child: GestureDetector(
                              onTap: () => editEntry(day, index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.subject.isEmpty
                                          ? "No Subject"
                                          : entry.subject,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: _textPri,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (entry.time.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.access_time_rounded,
                                              size: 16,
                                              color: _blue,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              entry.time,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: _blue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (entry.teacher.isNotEmpty)
                                          _infoChip(
                                            Icons.person_outline_rounded,
                                            entry.teacher,
                                          ),
                                        if (entry.teacher.isNotEmpty &&
                                            entry.room.isNotEmpty)
                                          const SizedBox(width: 16),
                                        if (entry.room.isNotEmpty)
                                          _infoChip(
                                            Icons.meeting_room_outlined,
                                            entry.room,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Delete',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: _surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Delete Entry",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _textPri,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Are you sure you want to delete this entry?",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _textSec,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              "Cancel",
                                              style: TextStyle(color: _textSec),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(
                                                () => allEntries[day]!.removeAt(
                                                  index,
                                                ),
                                              );
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        // Per-day FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: day,
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            onPressed: () {
              setState(() {
                allEntries[day]!.add(
                  TimetableEntry(subject: '', time: '', teacher: '', room: ''),
                );
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                editEntry(day, allEntries[day]!.length - 1);
              });
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: _textSec),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 16, color: _textSec)),
      ],
    );
  }

  // ── Weekend holiday screen ────────────────────────────────────────────────
  Widget _buildWeekendScreen() {
    final dayName = DateTime.now().weekday == 6 ? "Saturday" : "Sunday";

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Edit Timetable",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPri,
              ),
            ),
            Text(
              widget.className,
              style: const TextStyle(fontSize: 12, color: _textSec),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Save All",
            icon: const Icon(Icons.cloud_upload, color: _blue),
            onPressed: saveTimetable,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Text("🎉", style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 24),
            Text(
              "It's $dayName!",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _textPri,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "No classes today — enjoy your holiday! 🏖️",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: _textSec),
            ),
            const SizedBox(height: 32),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(child: Divider(color: _surface2, thickness: 1.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Need to edit?",
                      style: TextStyle(fontSize: 12, color: _textSec),
                    ),
                  ),
                  Expanded(child: Divider(color: _surface2, thickness: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Override button — lets teacher edit even on weekends
            GestureDetector(
              onTap: () => setState(() => _overrideWeekend = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_calendar_rounded, color: _blue, size: 18),
                    SizedBox(width: 10),
                    Text(
                      "Edit Monday's Timetable",
                      style: TextStyle(
                        fontSize: 15,
                        color: _blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _blue,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ── End weekend screen ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    // Show holiday screen on weekends unless teacher overrides
    if (isWeekend) return _buildWeekendScreen();

    final today = todayIndex;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Edit Timetable",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPri,
              ),
            ),
            Text(
              widget.className,
              style: const TextStyle(fontSize: 12, color: _textSec),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Save All",
            icon: const Icon(Icons.cloud_upload, color: _blue),
            onPressed: saveTimetable,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: _surface,
            child: TabBar(
              controller: _tabController,
              labelPadding: EdgeInsets.zero,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 3, color: _blue),
                insets: EdgeInsets.symmetric(horizontal: 16),
              ),
              labelColor: _blue,
              unselectedLabelColor: _textSec,
              tabs: List.generate(days.length, (i) {
                final isToday = today != null && i == today;
                return Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayLabels[i],
                        style: TextStyle(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: _blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: days.map(_buildDayTab).toList(),
      ),
    );
  }
}
