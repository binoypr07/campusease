import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PollsPage extends StatefulWidget {
  final String studentId;
  final String classYear;

  const PollsPage({
    super.key,
    required this.studentId,
    required this.classYear,
  });

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> {
  Map<String, String> selectedOptions = {};
  Map<String, bool> hasVoted = {};
  bool submitting = false;

  Future<void> submitVote(String pollId) async {
    final selected = selectedOptions[pollId];
    if (selected == null) return;

    setState(() => submitting = true);

    await FirebaseFirestore.instance
        .collection("polls")
        .doc(pollId)
        .collection("votes")
        .doc(widget.studentId)
        .set({"option": selected, "timestamp": FieldValue.serverTimestamp()});

    setState(() {
      submitting = false;
      hasVoted[pollId] = true; // mark as voted
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Vote submitted!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Polls")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("polls")
            .where("classYear", isEqualTo: widget.classYear)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = Timestamp.now();
          final allPolls = snapshot.data!.docs;

          /// FILTER POLLS BASED ON TIME
          final activePolls = allPolls.where((poll) {
            final start = poll["startTime"] as Timestamp;
            final end = poll["endTime"] as Timestamp;
            return start.compareTo(now) <= 0 && end.compareTo(now) >= 0;
          }).toList();

          if (activePolls.isEmpty) {
            return const Center(
              child: Text(
                "No active polls right now",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: activePolls.length,
            itemBuilder: (context, index) {
              final poll = activePolls[index];
              final pollId = poll.id;
              final question = poll["question"];
              final options = List<String>.from(poll["options"]);

              final voted = hasVoted[pollId] ?? false;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      /// OPTIONS
                      ...options.map(
                        (opt) => RadioListTile<String>(
                          title: Text(opt),
                          value: opt,
                          groupValue: selectedOptions[pollId],
                          onChanged: voted
                              ? null // disable after voting
                              : (val) {
                                  setState(() {
                                    selectedOptions[pollId] = val!;
                                  });
                                },
                        ),
                      ),

                      /// SUBMIT BUTTON
                      ElevatedButton(
                        onPressed:
                            submitting ||
                                voted ||
                                selectedOptions[pollId] == null
                            ? null
                            : () => submitVote(pollId),
                        child: submitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(voted ? "Already Voted" : "Submit Vote"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
