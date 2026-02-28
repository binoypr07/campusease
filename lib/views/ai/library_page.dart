import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- 2026 GROQ CONFIGURATION ---

  final String _groqApiKey =
      '';

  // Llama 3.1 is the stable instant model for 2026
  final String _model = 'llama-3.1-8b-instant';

  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    setState(() {
      _chatHistory.add({"role": "user", "text": userMessage});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {
              "role": "system",
              "content":
                  "You are the CampusEase Librarian. You provide helpful study advice and book info.",
            },
            {"role": "user", "content": userMessage},
          ],
          "temperature": 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'];

        setState(() {
          _chatHistory.add({"role": "ai", "text": aiText});
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error']['message'] ?? "Unknown Error");
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({"role": "ai", "text": "Error: $e"});
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background of the whole page
      appBar: AppBar(
        title: const Text(
          "AI Librarian",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final msg = _chatHistory[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      // Pure black box for AI, dark charcoal for User
                      color: isUser ? const Color(0xFF252525) : Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white12,
                        width: 1,
                      ), // Subtle outline
                    ),
                    child: Text(
                      msg["text"]!,
                      style: const TextStyle(
                        color: Colors.white, // All text is white
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.black,
                ),
              ),
            ),

          // --- Input Area ---
          Container(
            padding: const EdgeInsets.fromLTRB(
              10,
              10,
              10,
              30,
            ), // Added bottom padding for modern phones
            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onTap: _scrollToBottom,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Message Librarian...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 22,
                    child: Icon(Icons.arrow_upward, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
