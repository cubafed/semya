import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/firebase/firebase_app_holder.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(familyStorage);
});

class StorageRepository {
  StorageRepository(this._storage);

  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  Future<String> uploadAvatar({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref().child('avatars/$uid/avatar.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadChatImage({
    required String chatId,
    required File file,
  }) async {
    final id = _uuid.v4();
    final ref = _storage.ref().child('chat_media/$chatId/$id.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadVoiceMessage({
    required String chatId,
    required File file,
  }) async {
    final id = _uuid.v4();
    final ext = kIsWeb ? 'm4a' : 'm4a';
    final ref = _storage.ref().child('voice/$chatId/$id.$ext');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/mp4'),
    );
    return ref.getDownloadURL();
  }
}
