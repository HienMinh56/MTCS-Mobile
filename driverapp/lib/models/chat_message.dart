import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverName;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool read;
  final DateTime? readAt;  // Add readAt field to track when message was read

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverName,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.read,
    this.readAt,  // Optional, may be null if message is not read yet
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] ?? false,
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverName': receiverName,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }
  
  // Add copyWith method to support updating read status
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? receiverName,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    bool? read,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
    );
  }
}