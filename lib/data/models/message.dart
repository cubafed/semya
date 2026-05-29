import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, voice }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.text,
    this.mediaUrl,
    this.durationMs,
    this.readBy = const [],
  });

  final String id;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final int? durationMs;
  final DateTime createdAt;
  final List<String> readBy;

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      text: data['text'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      durationMs: data['durationMs'] as int?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'type': type.name,
        if (text != null) 'text': text,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': readBy,
        'status': 'sent',
      };

  static MessageType _parseType(String? raw) {
    switch (raw) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.text;
    }
  }
}
