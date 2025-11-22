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
  String? selectedOption;
  bool submitting = false;

  void submitVote(String pollId) async {
    if (selectedOption == null) return;

    setState(() => submitting = true);

    await FirebaseFirestore.instance
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(widget.studentId)
        .set({
          'option': selectedOption,
          'timestamp': FieldValue.serverTimestamp(),
        });

    setState(() => submitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vote submitted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Polls")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('polls')
            .where('classYear', isEqualTo: widget.classYear)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final polls = snapshot.data!.docs;

          if (polls.isEmpty)
            return const Center(child: Text('No polls available'));

          return ListView.builder(
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final poll = polls[index];
              final pollId = poll.id;
              final question = poll['question'];
              final options = List<String>.from(poll['options']);

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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...options.map(
                        (opt) => RadioListTile<String>(
                          title: Text(opt),
                          value: opt,
                          groupValue: selectedOption,
                          onChanged: (val) =>
                              setState(() => selectedOption = val),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: submitting ? null : () => submitVote(pollId),
                        child: submitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Vote"),
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
