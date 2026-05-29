import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../models/chat.dart';
import '../models/message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

class ChatRepository {
  ChatRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  Stream<List<Chat>> watchChatsForUser({
    required String spaceId,
    required String uid,
  }) {
    return _chats
        .where('spaceId', isEqualTo: spaceId)
        .where('members', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Chat.fromFirestore).toList());
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.messagesPageSize)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<Chat?> getChat(String chatId) async {
    final doc = await _chats.doc(chatId).get();
    if (!doc.exists) return null;
    return Chat.fromFirestore(doc);
  }

  Future<String> getOrCreateDirectChat({
    required String spaceId,
    required String myUid,
    required String peerUid,
  }) async {
    final chatId = Chat.directChatId(myUid, peerUid);
    final ref = _chats.doc(chatId);
    final existing = await ref.get();
    if (existing.exists) return chatId;

    final members = [myUid, peerUid]..sort();
    await ref.set({
      'spaceId': spaceId,
      'type': 'direct',
      'members': members,
      'memberHash': Chat.memberHashFor(members),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
    });
    return chatId;
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final batch = _firestore.batch();
    final msgRef = _chats.doc(chatId).collection('messages').doc();
    final chatRef = _chats.doc(chatId);

    batch.set(msgRef, {
      'senderId': senderId,
      'type': 'text',
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
      'status': 'sent',
    });

    batch.update(chatRef, {
      'lastMessage': {
        'text': text.trim(),
        'senderId': senderId,
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
