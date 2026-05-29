import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<List<AppUser>> watchSpaceMembers(String spaceId) {
    return _users
        .where('spaceId', isEqualTo: spaceId)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromFirestore).toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName)));
  }

  Future<void> updateLastSeen(String uid) async {
    await _users.doc(uid).set(
      {'lastSeen': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> updateDisplayName(String uid, String name) async {
    await _users.doc(uid).set(
      {'displayName': name.trim()},
      SetOptions(merge: true),
    );
  }
}
