import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherPollResultsPage extends StatelessWidget {
  final String className;

  const TeacherPollResultsPage({super.key, required this.className});

  /// Count votes for each option
  Map<String, int> countVotes(
    List<QueryDocumentSnapshot> votes,
    List<String> options,
  ) {
    Map<String, int> result = {for (var o in options) o: 0};

    for (var v in votes) {
      final opt = v['option'];
      if (result.containsKey(opt)) {
        result[opt] = result[opt]! + 1;
      }
    }
    return result;
  }

  /// Delete poll and all votes
  Future<void> deletePoll(String pollId, BuildContext context) async {
    try {
      final pollRef = FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId);

      final votes = await pollRef.collection('votes').get();

      for (var v in votes.docs) {
        await v.reference.delete();
      }

      await pollRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Poll deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting poll: $e")));
    }
  }

  /// Send poll result as announcement
  Future<void> sendPollResultAsAnnouncement({
    required String pollId,
    required String question,
    required Map<String, int> voteCount,
    required BuildContext context,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      StringBuffer body = StringBuffer();
      body.writeln("📊 Poll Result");
      body.writeln("");
      body.writeln(question);
      body.writeln("");

      voteCount.forEach((option, count) {
        body.writeln("• $option : $count votes");
      });

      await FirebaseFirestore.instance.collection("announcements").add({
        "title": "Poll Result",
        "body": body.toString(),
        "createdByUid": uid,
        "createdAt": FieldValue.serverTimestamp(),
        "target": {"type": "class", "value": className},
        "sourcePollId": pollId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Poll result sent as announcement")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.now();

    return Scaffold(
      appBar: AppBar(title: const Text("Poll Results")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('polls')
            .where('classYear', isEqualTo: className)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final polls = snapshot.data!.docs;

          final endedPolls = polls.where((poll) {
            final endTime = poll['endTime'] as Timestamp;
            return endTime.compareTo(now) <= 0;
          }).toList();

          if (endedPolls.isEmpty) {
            return const Center(child: Text("No ended polls"));
          }

          return ListView.builder(
            itemCount: endedPolls.length,
            itemBuilder: (context, index) {
              final poll = endedPolls[index];
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
                      /// Question + delete
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              question,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete Poll"),
                                  content: const Text(
                                    "Are you sure you want to delete this poll?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        deletePoll(pollId, context);
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// Votes
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('polls')
                            .doc(pollId)
                            .collection('votes')
                            .snapshots(),
                        builder: (context, voteSnapshot) {
                          if (!voteSnapshot.hasData) {
                            return const Text("Loading votes...");
                          }

                          final votes = voteSnapshot.data!.docs;
                          final voteCount = countVotes(votes, options);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...voteCount.entries.map(
                                (e) => ListTile(
                                  dense: true,
                                  title: Text(e.key),
                                  trailing: Text(e.value.toString()),
                                ),
                              ),

                              const SizedBox(height: 8),

                              /// Send announcement button
                              ElevatedButton.icon(
                                icon: const Icon(Icons.campaign),
                                label: const Text("Send as Announcement"),
                                onPressed: () {
                                  sendPollResultAsAnnouncement(
                                    pollId: pollId,
                                    question: question,
                                    voteCount: voteCount,
                                    context: context,
                                  );
                                },
                              ),
                            ],
                          );
                        },
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
