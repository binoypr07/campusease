import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String? id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;
  final String status;

  // ── Basic reply (the quoted text) ─────────────────────────────────────────
  final String? replyTo;

  // ── Rich reply metadata ───────────────────────────────────────────────────
  final String? replyToSender; // name of person being replied to
  final String?
  replyToType; // 'text' | 'image' | 'video' | 'voice' | 'pdf' | 'file'
  final String? replyToMedia; // image/video URL for thumbnail in quote

  final List<String> seenBy;
  final String messageType;
  final int? voiceDuration;
  final String? thumbnailUrl;
  final String? fileName;

  MessageModel({
    this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.status = 'sent',
    this.replyTo,
    this.replyToSender,
    this.replyToType,
    this.replyToMedia,
    this.seenBy = const [],
    this.messageType = 'text',
    this.voiceDuration,
    this.thumbnailUrl,
    this.fileName, int? fileSize,
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
      replyToSender: map['replyToSender'],
      replyToType: map['replyToType'],
      replyToMedia: map['replyToMedia'],
      seenBy: List<String>.from(map['seenBy'] ?? []),
      messageType: map['messageType'] ?? 'text',
      voiceDuration: map['voiceDuration'],
      thumbnailUrl: map['thumbnailUrl'],
      fileName: map['fileName'],
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
      'replyToSender': replyToSender,
      'replyToType': replyToType,
      'replyToMedia': replyToMedia,
      'seenBy': seenBy,
      'messageType': messageType,
      'voiceDuration': voiceDuration,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
    };
  }
}
