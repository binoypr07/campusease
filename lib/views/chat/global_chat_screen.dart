import 'dart:convert';
import 'package:campusease/views/chat/media/media_uploader_widget.dart';
import 'package:campusease/views/chat/media/media_viewer_page.dart';
import 'package:campusease/views/chat/members_list_screen.dart';
import 'package:campusease/views/chat/voicechat/voice_message_player.dart';
import 'package:campusease/views/chat/voicechat/voice_recorder_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/message_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:campusease/core/services/notification_handler.dart';

class GlobalChatScreen extends StatefulWidget {
  final String classId;
  const GlobalChatScreen({super.key, required this.classId});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen>
    with WidgetsBindingObserver {
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
  bool isRecording = false;
  bool isUserInChat = false;

  bool _showScrollToBottom = false;
  String? _highlightedMessageId;
  List<QueryDocumentSnapshot> _docs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _setupWhatsAppNotifications();
    _markUserInChat(true);
    NotificationHandler.setActiveChat(widget.classId);
    syncWithRender("System_Wakeup", "User_Entry");

    scrollController.addListener(() {
      final showBtn = scrollController.offset > 300;
      if (showBtn != _showScrollToBottom) {
        setState(() => _showScrollToBottom = showBtn);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _markUserInChat(false);
    NotificationHandler.setActiveChat(null);
    messageFocusNode.dispose();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _markUserInChat(true);
      NotificationHandler.setActiveChat(widget.classId);
    } else if (state == AppLifecycleState.paused) {
      _markUserInChat(false);
      NotificationHandler.setActiveChat(null);
    }
  }

  Future<void> _markUserInChat(bool inChat) async {
    if (uid.isEmpty) return;
    setState(() => isUserInChat = inChat);
    try {
      await FirebaseFirestore.instance
          .collection('user_chat_status')
          .doc(uid)
          .set({
            'currentChatId': inChat ? widget.classId : null,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating chat status: $e");
    }
  }

  Future<void> _setupWhatsAppNotifications() async {
    try {
      String topicName = widget.classId.replaceAll(' ', '_');
      await FirebaseMessaging.instance.subscribeToTopic(topicName);
    } catch (e) {
      print("Error subscribing to topic: $e");
    }
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
      _markUserInChat(true);
    }
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('class_chats')
        .doc(widget.classId)
        .collection('messages')
        .get();
    final uniqueMembers = <String>{};
    for (var doc in messagesSnapshot.docs) {
      final senderId = doc.data()['senderId'];
      if (senderId != null && senderId.isNotEmpty) {
        uniqueMembers.add(senderId);
      }
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
      await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "sender": senderName,
              "text": msg,
              "classId": widget.classId,
              "time": DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print("Render Sync: Server is waking up or offline. (Ignoring error)");
    }
  }

  Future<void> _sendWhatsAppStyleNotification(String messageText) async {
    final url = Uri.parse('https://shade-0pxb.onrender.com/notification');
    String topicName = widget.classId.replaceAll(' ', '_');
    try {
      await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "shade-key": "",
        },
        body: jsonEncode({
          "from": "CampusEase",
          "to": "/topics/$topicName",
          "title": widget.classId,
          "body": "$name: $messageText",
          "data": {
            "classId": widget.classId,
            "senderId": uid,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          },
        }),
      );
    } catch (e) {
      print("Failed to send WhatsApp notification: $e");
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

  // ── Date helpers ──────────────────────────────────────────────────────────
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);
    String label;
    if (msgDay == today) {
      label = 'Today';
    } else if (msgDay == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, y').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12, thickness: 0.5)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2C34),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12, width: 0.5),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.white12, thickness: 0.5)),
        ],
      ),
    );
  }

  final Map<String, GlobalKey> _messageKeys = {};

  void _jumpToMessage(String replyToText) {
    // 1. Find the index of the target message in _docs
    int targetIndex = -1;
    String targetId = '';
    for (int i = 0; i < _docs.length; i++) {
      final data = _docs[i].data() as Map<String, dynamic>;
      if ((data['message'] ?? '') == replyToText) {
        targetIndex = i;
        targetId = _docs[i].id;
        break;
      }
    }
    if (targetIndex == -1) return;

    // 2. Estimate scroll offset.
    //    index 0 = bottom (offset 0). index N = N bubbles up from bottom.
    const double avgBubbleHeight = 80.0;
    final double estimatedOffset = targetIndex * avgBubbleHeight;
    final double maxOffset = scrollController.position.maxScrollExtent;
    final double clampedOffset = estimatedOffset.clamp(0.0, maxOffset);

    // 3. Jump instantly to near the target, then do a smooth settle
    scrollController.jumpTo(clampedOffset);

    // 4. After the jump, try ensureVisible if the widget is now in the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _messageKeys[targetId];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.4,
        );
      }

      // 5. Flash the highlight regardless
      setState(() => _highlightedMessageId = targetId);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _highlightedMessageId = null);
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────

  void sendMessage() {
    String msg = messageController.text.trim();
    if (msg.isEmpty) {
      setState(() => fieldError = "Empty!");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => fieldError = null);
      });
      return;
    }
    messageController.clear();
    final tempReplyingMessage = replyingMessage;
    final tempEditingMessage = editingMessage;
    setState(() {
      replyingMessage = null;
      editingMessage = null;
      fieldError = null;
    });
    if (tempEditingMessage != null) {
      FirebaseFirestore.instance
          .collection('class_chats')
          .doc(widget.classId)
          .collection('messages')
          .doc(tempEditingMessage.id)
          .update({'message': msg});
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
            'replyToSender': tempReplyingMessage?.senderName,
            'replyToType': tempReplyingMessage?.messageType,
            'replyToMedia':
                (tempReplyingMessage?.messageType == 'image' ||
                    tempReplyingMessage?.messageType == 'video')
                ? tempReplyingMessage?.message
                : null,
            'seenBy': [uid],
            'messageType': 'text',
          });
      syncWithRender(msg, name);
      _sendWhatsAppStyleNotification(msg);
    }
  }

  Future<void> sendMediaMessage(
    String mediaUrl,
    String mediaType, {
    String? thumbnailUrl,
    String? fileName,
  }) async {
    String emoji;
    switch (mediaType) {
      case 'image':
        emoji = '📷 Photo';
        break;
      case 'video':
        emoji = '🎬 Video';
        break;
      case 'pdf':
        emoji = '📄 PDF';
        break;
      case 'file':
        emoji = '📎 File';
        break;
      default:
        emoji = '📎 File';
    }
    await FirebaseFirestore.instance
        .collection('class_chats')
        .doc(widget.classId)
        .collection('messages')
        .add({
          'senderId': uid,
          'senderName': name,
          'senderRole': role,
          'message': mediaUrl,
          'messageType': mediaType,
          'thumbnailUrl': thumbnailUrl,
          'fileName': fileName,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'delivered',
          'replyTo': replyingMessage?.message,
          'replyToSender': replyingMessage?.senderName,
          'replyToType': replyingMessage?.messageType,
          'replyToMedia':
              (replyingMessage?.messageType == 'image' ||
                  replyingMessage?.messageType == 'video')
              ? replyingMessage?.message
              : null,
          'seenBy': [uid],
        });
    setState(() => replyingMessage = null);
    syncWithRender(emoji, name);
    _sendWhatsAppStyleNotification(emoji);
  }

  Future<void> sendVoiceMessage(String audioPath, int duration) async {
    try {
      const String myCloudName = "";
      const String myUploadPreset = "my_voice_preset";
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$myCloudName/upload",
      );
      var request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = myUploadPreset;
      request.fields['resource_type'] = 'video';
      if (kIsWeb) {
        final response = await http.get(Uri.parse(audioPath));
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            response.bodyBytes,
            filename: 'voice.m4a',
          ),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', audioPath));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String voiceUrl = responseData['secure_url'];
        await FirebaseFirestore.instance
            .collection('class_chats')
            .doc(widget.classId)
            .collection('messages')
            .add({
              'senderId': uid,
              'senderName': name,
              'message': voiceUrl,
              'messageType': 'voice',
              'voiceDuration': duration,
              'timestamp': FieldValue.serverTimestamp(),
              'seenBy': [uid],
            });
        _sendWhatsAppStyleNotification("🎤 Voice message");
      }
    } catch (e) {
      print("Error: $e");
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
          if (msg.messageType == 'text')
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
            child: Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('class_chats')
                      .doc(widget.classId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    _docs = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      controller: scrollController,
                      itemCount: _docs.length,
                      padding: const EdgeInsets.all(10),
                      itemBuilder: (context, index) {
                        var data = _docs[index].data() as Map<String, dynamic>;
                        String docId = _docs[index].id;
                        List seenBy = data['seenBy'] ?? [];
                        if (data['senderId'] != uid) {
                          _markAsSeen(docId, seenBy);
                        }

                        _messageKeys.putIfAbsent(docId, () => GlobalKey());

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
                          replyToSender: data['replyToSender'],
                          replyToType: data['replyToType'],
                          replyToMedia: data['replyToMedia'],
                          messageType: data['messageType'] ?? 'text',
                          voiceDuration: data['voiceDuration'],
                          thumbnailUrl: data['thumbnailUrl'],
                          fileName: data['fileName'],
                        );

                        // Date separator
                        bool showDateHeader = false;
                        final DateTime currentDate =
                            (data['timestamp'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                        if (index == _docs.length - 1) {
                          showDateHeader = true;
                        } else {
                          final prevData =
                              _docs[index + 1].data() as Map<String, dynamic>;
                          final DateTime prevDate =
                              (prevData['timestamp'] as Timestamp?)?.toDate() ??
                              DateTime.now();
                          if (!_isSameDay(currentDate, prevDate)) {
                            showDateHeader = true;
                          }
                        }

                        return Column(
                          key: _messageKeys[docId],
                          children: [
                            if (showDateHeader)
                              _buildDateSeparator(currentDate),
                            SwipeToReplyItem(
                              message: msg,
                              isMe: msg.senderId == uid,
                              isHighlighted: _highlightedMessageId == docId,
                              onReply: (m) =>
                                  setState(() => replyingMessage = m),
                              onLongPress: (details, m) => _showWhatsAppMenu(
                                context,
                                details,
                                m,
                                seenBy,
                              ),
                              onReplyTap: (replyText) =>
                                  _jumpToMessage(replyText),
                              statusIcon: _buildStatusIcon(seenBy),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                // Scroll-to-bottom button
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2C34),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (replyingMessage != null) _buildReplyPreview(),
          if (isRecording)
            VoiceRecorderWidget(
              onCancel: () => setState(() => isRecording = false),
              onSend: (path, duration) {
                setState(() => isRecording = false);
                sendVoiceMessage(path, duration);
              },
            )
          else
            _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final rm = replyingMessage!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
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
            if (rm.messageType == 'image' || rm.messageType == 'video')
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  rm.messageType == 'video' && rm.thumbnailUrl != null
                      ? rm.thumbnailUrl!
                      : rm.message,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: Colors.black38,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
              ),
            if (rm.messageType == 'image' || rm.messageType == 'video')
              const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rm.senderName,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rm.messageType == 'voice'
                        ? '🎤 Voice message'
                        : rm.messageType == 'image'
                        ? '📷 Photo'
                        : rm.messageType == 'video'
                        ? '🎬 Video'
                        : rm.messageType == 'pdf'
                        ? '📄 ${rm.fileName ?? 'PDF'}'
                        : rm.messageType == 'file'
                        ? '📎 ${rm.fileName ?? 'File'}'
                        : rm.message,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              onPressed: () => setState(() => replyingMessage = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    bool isTextEmpty = messageController.text.trim().isEmpty;
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
            child: MediaUploaderWidget(
              onUploaded: (url, type, {thumbnailUrl, fileName, fileSize}) =>
                  sendMediaMessage(
                    url,
                    type,
                    thumbnailUrl: thumbnailUrl,
                    fileName: fileName,
                    // fileSize ignored for now
                  ),
              messageController: messageController,
              messageFocusNode: messageFocusNode,
              onChanged: () => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (isTextEmpty) {
                setState(() => isRecording = true);
              } else {
                sendMessage();
              }
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF00A884),
              child: Icon(
                isTextEmpty ? Icons.mic : Icons.send,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SwipeToReplyItem
// ─────────────────────────────────────────────────────────────────────────────

class SwipeToReplyItem extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final bool isHighlighted;
  final Function(MessageModel) onReply;
  final Function(TapDownDetails, MessageModel) onLongPress;
  final Function(String) onReplyTap;
  final Widget statusIcon;

  const SwipeToReplyItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onLongPress,
    required this.onReplyTap,
    required this.statusIcon,
    this.isHighlighted = false,
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

  void _openMediaViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaViewerPage(
          mediaUrl: widget.message.message,
          mediaType: widget.message.messageType,
          senderName: widget.message.senderName,
          timestamp: widget.message.timestamp,
        ),
      ),
    );
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildReplyQuote(MessageModel msg) {
    final replyType = msg.replyToType ?? 'text';
    final replyMedia = msg.replyToMedia;
    final replyText = msg.replyTo ?? '';
    final replySender = msg.replyToSender ?? '';

    return GestureDetector(
      onTap: () => widget.onReplyTap(replyText),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Colors.blueAccent, width: 4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (replySender.isNotEmpty)
                      Text(
                        replySender,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      replyType == 'voice'
                          ? '🎤 Voice message'
                          : replyType == 'image'
                          ? '📷 Photo'
                          : replyType == 'video'
                          ? '🎬 Video'
                          : replyType == 'pdf'
                          ? '📄 PDF'
                          : replyType == 'file'
                          ? '📎 File'
                          : replyText,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if ((replyType == 'image' || replyType == 'video') &&
                replyMedia != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Image.network(
                  replyMedia,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: Colors.black38,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white24,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onTapDown: (details) => _tapDetails = details,
      onLongPress: () {
        if (_tapDetails != null) {
          widget.onLongPress(_tapDetails!, widget.message);
        }
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: widget.isHighlighted
                      ? const Color(0xFF5A4A00)
                      : widget.isMe
                      ? const Color(0xFF075E54)
                      : const Color(0xFF1F2C34),
                  borderRadius: BorderRadius.circular(12),
                  border: widget.isHighlighted
                      ? Border.all(color: const Color(0xFFFFD700), width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.replyTo != null)
                      _buildReplyQuote(widget.message),
                    if (!widget.isMe)
                      Text(
                        widget.message.senderName,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (widget.message.messageType == 'voice')
                      VoiceMessagePlayer(
                        voiceUrl: widget.message.message,
                        duration: widget.message.voiceDuration ?? 0,
                        isMe: widget.isMe,
                      )
                    else if (widget.message.messageType == 'image')
                      GestureDetector(
                        onTap: () => _openMediaViewer(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.message.message,
                            width: 220,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, prog) {
                              if (prog == null) return child;
                              return const SizedBox(
                                width: 220,
                                height: 140,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00A884),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 220,
                              height: 140,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white38,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (widget.message.messageType == 'video')
                      GestureDetector(
                        onTap: () => _openMediaViewer(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              widget.message.thumbnailUrl != null
                                  ? Image.network(
                                      widget.message.thumbnailUrl!,
                                      width: 220,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (_, child, prog) {
                                        if (prog == null) return child;
                                        return Container(
                                          width: 220,
                                          height: 140,
                                          color: Colors.black38,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF00A884),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 220,
                                        height: 140,
                                        color: Colors.black38,
                                        child: const Icon(
                                          Icons.videocam_rounded,
                                          color: Colors.white24,
                                          size: 60,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 220,
                                      height: 140,
                                      color: Colors.black38,
                                      child: const Icon(
                                        Icons.videocam_rounded,
                                        color: Colors.white24,
                                        size: 60,
                                      ),
                                    ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (widget.message.messageType == 'pdf' ||
                        widget.message.messageType == 'file')
                      GestureDetector(
                        onTap: () => _openFile(widget.message.message),
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12, width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: widget.message.messageType == 'pdf'
                                      ? const Color(
                                          0xFFE94E4E,
                                        ).withOpacity(0.15)
                                      : const Color(
                                          0xFF5E5CE6,
                                        ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  widget.message.messageType == 'pdf'
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.insert_drive_file_rounded,
                                  color: widget.message.messageType == 'pdf'
                                      ? const Color(0xFFE94E4E)
                                      : const Color(0xFF5E5CE6),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.message.fileName ??
                                          (widget.message.messageType == 'pdf'
                                              ? 'Document.pdf'
                                              : 'File'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.message.messageType.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.download_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        widget.message.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
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
