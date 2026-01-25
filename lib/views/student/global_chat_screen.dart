import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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

  Widget _buildStatusIcon(List? seenBy) {
    bool isRead = (seenBy != null && seenBy.length > 1);
    return Icon(
      Icons.done_all,
      size: 16,
      color: isRead ? Colors.blue : Colors.white54,
    );
  }

  Future<void> sendMessage() async {
    String msg = messageController.text.trim();
    if (msg.isEmpty) return;

    if (editingMessage != null) {
      await FirebaseFirestore.instance
          .collection('class_chats')
          .doc(widget.classId)
          .collection('messages')
          .doc(editingMessage!.id)
          .update({'message': msg});
      setState(() => editingMessage = null);
    } else {
      final messageData = {
        'senderId': uid,
        'senderName': name,
        'senderRole': role,
        'message': msg,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'delivered',
        'replyTo': replyingMessage?.message,
        'seenBy': [uid],
      };

      await FirebaseFirestore.instance
          .collection('class_chats')
          .doc(widget.classId)
          .collection('messages')
          .add(messageData);

      setState(() => replyingMessage = null);
    }
    messageController.clear();
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
        title: Text("Class Chat: ${widget.classId}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('class_chats')
                  .doc(widget.classId)
                  .collection('messages')
                  .orderBy(
                    'timestamp',
                    descending: true,
                  ) // Sort Newest first for reverse
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // WhatsApp style: anchored to bottom
                  controller: scrollController,
                  itemCount: docs.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    List seenBy = data['seenBy'] ?? [];

                    if (data['senderId'] != uid) {
                      _markAsSeen(docId, seenBy);
                    }

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
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF1F2C34),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              focusNode: messageFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Type here",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              editingMessage != null ? Icons.check : Icons.send,
              color: Colors.blueAccent,
            ),
            onPressed: sendMessage,
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
