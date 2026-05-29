import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType { direct, group }

class LastMessagePreview {
  const LastMessagePreview({
    required this.text,
    required this.senderId,
    required this.type,
    required this.createdAt,
  });

  final String text;
  final String senderId;
  final String type;
  final DateTime createdAt;

  factory LastMessagePreview.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return LastMessagePreview(
        text: '',
        senderId: '',
        type: 'text',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    return LastMessagePreview(
      text: data['text'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      type: data['type'] as String? ?? 'text',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class Chat {
  const Chat({
    required this.id,
    required this.spaceId,
    required this.type,
    required this.members,
    required this.memberHash,
    this.lastMessage,
    this.updatedAt,
    this.groupName,
  });

  final String id;
  final String spaceId;
  final ChatType type;
  final List<String> members;
  final String memberHash;
  final LastMessagePreview? lastMessage;
  final DateTime? updatedAt;
  final String? groupName;

  bool isDirectWith(String uid) =>
      type == ChatType.direct && members.contains(uid);

  factory Chat.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Chat(
      id: doc.id,
      spaceId: data['spaceId'] as String? ?? '',
      type: data['type'] == 'group' ? ChatType.group : ChatType.direct,
      members: List<String>.from(data['members'] as List? ?? []),
      memberHash: data['memberHash'] as String? ?? '',
      lastMessage: LastMessagePreview.fromMap(
        data['lastMessage'] as Map<String, dynamic>?,
      ),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      groupName: (data['groupMeta'] as Map<String, dynamic>?)?['name']
          as String?,
    );
  }

  static String directChatId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  static String memberHashFor(List<String> uids) {
    final sorted = List<String>.from(uids)..sort();
    return sorted.join('_');
  }
}
