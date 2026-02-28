import 'package:campusease/views/teacher/timetable/time_table_entry.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

const _bg = Color(0xFF121212);
const _surface = Color(0xFF1E1E1E);
const _surface2 = Color(0xFF2A2A2A);
const _blue = Colors.blue;
const _textPri = Colors.white;
const _textSec = Color(0xFF9E9E9E);

class TimetablePage extends StatefulWidget {
  final String className;
  const TimetablePage({super.key, required this.className});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage>
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
  Map<String, List<TimetableEntry>> allEntries = {};
  bool loading = true;

  // null means it's a weekend
  int? get todayIndex {
    final weekday = DateTime.now().weekday;
    if (weekday >= 1 && weekday <= 5) return weekday - 1;
    return null; // Saturday=6, Sunday=7
  }

  bool get isWeekend => todayIndex == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: days.length,
      vsync: this,
      initialIndex: todayIndex ?? 0, // fallback to Mon but won't be shown
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    // ── Weekend screen ──────────────────────────────────────────────────────
    if (isWeekend) {
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
                "Time Table",
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
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing holiday icon
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
              // Divider with label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: _surface2, thickness: 1.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Next school day",
                        style: TextStyle(fontSize: 12, color: _textSec),
                      ),
                    ),
                    Expanded(child: Divider(color: _surface2, thickness: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Monday preview chip
              GestureDetector(
                onTap: () {
                  // jump to the timetable starting from Monday
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _WeekdayTimetableView(
                        className: widget.className,
                        allEntries: allEntries,
                        startIndex: 0, // Monday
                      ),
                    ),
                  );
                },
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
                      Icon(
                        Icons.calendar_today_rounded,
                        color: _blue,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "View Monday's Timetable",
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
    // ── End weekend screen ──────────────────────────────────────────────────

    final today = todayIndex!;

    return _WeekdayTimetableView(
      className: widget.className,
      allEntries: allEntries,
      startIndex: today,
    );
  }
}

// ── Extracted weekday view so weekend "View Monday" button can reuse it ──────
class _WeekdayTimetableView extends StatefulWidget {
  final String className;
  final Map<String, List<TimetableEntry>> allEntries;
  final int startIndex;

  const _WeekdayTimetableView({
    required this.className,
    required this.allEntries,
    required this.startIndex,
  });

  @override
  State<_WeekdayTimetableView> createState() => _WeekdayTimetableViewState();
}

class _WeekdayTimetableViewState extends State<_WeekdayTimetableView>
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

  int? get todayIndex {
    final weekday = DateTime.now().weekday;
    if (weekday >= 1 && weekday <= 5) return weekday - 1;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: days.length,
      vsync: this,
      initialIndex: widget.startIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = todayIndex;

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
              "Time Table",
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
        children: List.generate(days.length, (dayIdx) {
          final day = days[dayIdx];
          final entries = widget.allEntries[day] ?? [];
          final isToday = today != null && dayIdx == today;

          if (entries.isEmpty) return _buildEmptyState(isToday);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: entries.length,
            itemBuilder: (context, index) =>
                _buildEntryCard(entries[index], index),
          );
        }),
      ),
    );
  }

  Widget _buildEntryCard(TimetableEntry entry, int index) {
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
            Container(width: 3, color: _blue),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.subject.isEmpty ? "No Subject" : entry.subject,
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
                          borderRadius: BorderRadius.circular(20),
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
                        if (entry.teacher.isNotEmpty && entry.room.isNotEmpty)
                          const SizedBox(width: 16),
                        if (entry.room.isNotEmpty)
                          _infoChip(Icons.meeting_room_outlined, entry.room),
                      ],
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

  Widget _buildEmptyState(bool isToday) {
    return Center(
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
              Icons.event_available_rounded,
              size: 52,
              color: _blue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isToday ? "No classes today! 🎉" : "No classes scheduled",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _textPri,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isToday ? "Enjoy your free day" : "Nothing added for this day",
            style: const TextStyle(fontSize: 13, color: _textSec),
          ),
        ],
      ),
    );
  }
}
