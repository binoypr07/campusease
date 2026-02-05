import 'dart:convert';

import 'package:campusease/views/chat/members_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../models/message_model.dart';

class GlobalChatScreen extends StatefulWidget {
  final String classId;
  const GlobalChatScreen({super.key, required this.classId});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode messageFocusNode = FocusNode();

  String uid = "";
  String name = "Unknown";
  String role = "student";
  String userDept = "";
  MessageModel? editingMessage;
  MessageModel? replyingMessage;
  String? fieldError;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // Wake up the Render server immediately on screen load
    syncWithRender("System_Wakeup", "User_Entry");
  }

  @override
  void dispose() {
    messageFocusNode.dispose();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    uid = currentUser.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted && userDoc.exists) {
      setState(() {
        name = userDoc.data()?['name'] ?? 'Unknown';
        role = userDoc.data()?['role'] ?? 'student';
        userDept = userDoc.data()?['department'] ?? '';
      });
    }
  }

  void _markAsSeen(String messageId, List? seenBy) {
    if (seenBy == null || !seenBy.contains(uid)) {
      FirebaseFirestore.instance
          .collection('class_chats')
          .doc(widget.classId)
          .collection('messages')
          .doc(messageId)
          .update({
            'seenBy': FieldValue.arrayUnion([uid]),
          })
          .catchError((e) => print("Seen update failed: $e"));
    }
  }

  Future<void> syncWithRender(String msg, String senderName) async {
    final url = Uri.parse('https://shade-0pxb.onrender.com/users');
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender": senderName,
          "text": msg,
          "classId": widget.classId,
          "time": DateTime.now().toIso8601String(),
        }),
      );
      print("Sent to Render successfully");
    } catch (e) {
      print("Render server is likely asleep or error: $e");
    }
  }

  Widget _buildStatusIcon(List? seenBy) {
    bool isRead = (seenBy != null && seenBy.length > 1);
    return Icon(
      Icons.done_all,
      size: 16,
      color: isRead ? Colors.blue : Colors.white54,
    );
  }

  // FIXED: Instant clearing logic
  void sendMessage() {
    String msg = messageController.text.trim();

    if (msg.isEmpty) {
      setState(() => fieldError = "Empty!");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => fieldError = null);
      });
      return;
    }

    // 1. CLEAR IMMEDIATELY (Feels instant to user)
    messageController.clear();

    // 2. CAPTURE DATA & RESET UI STATE
    final tempReplyingMessage = replyingMessage;
    final tempEditingMessage = editingMessage;

    setState(() {
      replyingMessage = null;
      editingMessage = null;
      fieldError = null;
    });

    // 3. RUN DATABASE UPDATE IN BACKGROUND (No 'await' here to prevent UI lag)
    if (tempEditingMessage != null) {
      FirebaseFirestore.instance
          .collection('class_chats')
          .doc(widget.classId)
          .collection('messages')
          .doc(tempEditingMessage.id)
          .update({'message': msg});

      // Sync edit to Render
      syncWithRender("(Edited) $msg", name);
    } else {
      FirebaseFirestore.instance
          .collection('class_chats')
          .doc(widget.classId)
          .collection('messages')
          .add({
            'senderId': uid,
            'senderName': name,
            'senderRole': role,
            'message': msg,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'delivered',
            'replyTo': tempReplyingMessage?.message,
            'seenBy': [uid],
          });

      // Sync new message to Render
      syncWithRender(msg, name);
    }
  }

  void _showSeenByList(List seenByIDs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Message Info",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: seenByIDs.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(seenByIDs[index])
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      var data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data == null) return const SizedBox();
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          data['name'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          data['role'] ?? 'student',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: const Icon(
                          Icons.done_all,
                          color: Colors.blue,
                          size: 16,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showWhatsAppMenu(
    BuildContext context,
    TapDownDetails details,
    MessageModel msg,
    List? seenBy,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      color: Colors.grey[900],
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        if (msg.senderId == uid) ...[
          const PopupMenuItem(
            value: 'info',
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Colors.white),
              title: Text("Info", style: TextStyle(color: Colors.white)),
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: Colors.white),
              title: Text("Edit", style: TextStyle(color: Colors.white)),
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ),
        ] else
          const PopupMenuItem(
            value: 'reply',
            child: ListTile(
              leading: Icon(Icons.reply, color: Colors.white),
              title: Text("Reply", style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    ).then((value) {
      if (value == 'info') _showSeenByList(seenBy ?? [msg.senderId]);
      if (value == 'edit') {
        setState(() {
          editingMessage = msg;
          messageController.text = msg.message;
          messageFocusNode.requestFocus();
        });
      }
      if (value == 'delete') {
        FirebaseFirestore.instance
            .collection('class_chats')
            .doc(widget.classId)
            .collection('messages')
            .doc(msg.id)
            .delete();
      }
      if (value == 'reply') setState(() => replyingMessage = msg);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C34),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.classId,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Tap for group info",
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MembersListScreen(classId: widget.classId),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('class_chats')
                  .doc(widget.classId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  controller: scrollController,
                  itemCount: docs.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    List seenBy = data['seenBy'] ?? [];
                    if (data['senderId'] != uid) _markAsSeen(docId, seenBy);
                    final msg = MessageModel(
                      id: docId,
                      senderId: data['senderId'] ?? '',
                      senderName: data['senderName'] ?? 'Unknown',
                      senderRole: data['senderRole'] ?? 'student',
                      message: data['message'] ?? '',
                      timestamp:
                          (data['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      status: data['status'] ?? 'delivered',
                      replyTo: data['replyTo'],
                    );
                    return SwipeToReplyItem(
                      message: msg,
                      isMe: msg.senderId == uid,
                      onReply: (m) => setState(() => replyingMessage = m),
                      onLongPress: (details, m) =>
                          _showWhatsAppMenu(context, details, m, seenBy),
                      statusIcon: _buildStatusIcon(seenBy),
                    );
                  },
                );
              },
            ),
          ),
          if (replyingMessage != null) _buildReplyPreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF1F2C34),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Colors.blueAccent, width: 4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replyingMessage!.senderName,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    replyingMessage!.message,
                    style: const TextStyle(color: Colors.white60),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () => setState(() => replyingMessage = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2C34),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              focusNode: messageFocusNode,
              maxLines: 5,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                errorText: fieldError,
                errorStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  height: 0.1,
                ),
                hintText: "Type a message...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2A3942),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blueAccent,
              child: IconButton(
                icon: Icon(
                  editingMessage != null ? Icons.check : Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SwipeToReplyItem extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final Function(MessageModel) onReply;
  final Function(TapDownDetails, MessageModel) onLongPress;
  final Widget statusIcon;
  const SwipeToReplyItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onLongPress,
    required this.statusIcon,
  });
  @override
  State<SwipeToReplyItem> createState() => _SwipeToReplyItemState();
}

class _SwipeToReplyItemState extends State<SwipeToReplyItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  double _dragExtent = 0;
  TapDownDetails? _tapDetails;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_controller);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      if (_dragExtent < 0) _dragExtent = 0;
      if (_dragExtent > 70) _dragExtent = 70;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent >= 70) widget.onReply(widget.message);
    setState(() {
      _animation = Tween<Offset>(
        begin: Offset(_dragExtent / MediaQuery.of(context).size.width, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
      _dragExtent = 0;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onTapDown: (details) => _tapDetails = details,
      onLongPress: () {
        if (_tapDetails != null)
          widget.onLongPress(_tapDetails!, widget.message);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Opacity(
                  opacity: (_dragExtent / 70).clamp(0.0, 1.0),
                  child: const Icon(Icons.reply, color: Colors.blueAccent),
                ),
              ),
            ),
          ),
          SlideTransition(
            position: _animation.value == Offset.zero
                ? AlwaysStoppedAnimation(
                    Offset(_dragExtent / MediaQuery.of(context).size.width, 0),
                  )
                : _animation,
            child: Align(
              alignment: widget.isMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? const Color(0xFF075E54)
                      : const Color(0xFF1F2C34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.replyTo != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            left: BorderSide(
                              color: Colors.blueAccent,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.message.replyTo!,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (!widget.isMe)
                      Text(
                        widget.message.senderName,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      widget.message.message,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat(
                            'hh:mm a',
                          ).format(widget.message.timestamp),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                        if (widget.isMe) ...[
                          const SizedBox(width: 4),
                          widget.statusIcon,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
