import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String classYear;

  const FeedbackPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.classYear,
  });

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController feedbackController = TextEditingController();
  bool sending = false;

  void submitFeedback() async {
    if (feedbackController.text.isEmpty) return;

    setState(() => sending = true);

    try {
      // Save feedback
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'classYear': widget.classYear.trim(), // trim to avoid extra spaces
        'feedback': feedbackController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Feedback submitted')));

      feedbackController.clear();
    } catch (e) {
      print("ERROR submitting feedback: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting feedback: $e')));
    } finally {
      setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Your Feedback",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sending ? null : submitFeedback,
              child: sending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
