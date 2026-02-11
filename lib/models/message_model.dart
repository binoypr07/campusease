import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String? id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;
  final String status;
  final String? replyTo;
  final List<String> seenBy;
  final String messageType; // NEW: 'text' or 'voice'
  final int? voiceDuration; // NEW: Duration in seconds for voice messages

  MessageModel({
    this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.status = 'sent',
    this.replyTo,
    this.seenBy = const [],
    this.messageType = 'text', // NEW: Default to 'text'
    this.voiceDuration, // NEW: Optional voice duration
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? 'student',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'sent',
      replyTo: map['replyTo'],
      seenBy: List<String>.from(map['seenBy'] ?? []),
      messageType: map['messageType'] ?? 'text', // NEW
      voiceDuration: map['voiceDuration'], // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'timestamp': timestamp,
      'status': status,
      'replyTo': replyTo,
      'seenBy': seenBy,
      'messageType': messageType, // NEW
      'voiceDuration': voiceDuration, // NEW
    };
  }
}
