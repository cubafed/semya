import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, member }

class AppUser {
  const AppUser({
    required this.uid,
    required this.spaceId,
    required this.displayName,
    this.photoUrl,
    this.lastSeen,
    this.fcmTokens = const [],
    this.role = UserRole.member,
  });

  final String uid;
  final String spaceId;
  final String displayName;
  final String? photoUrl;
  final DateTime? lastSeen;
  final List<String> fcmTokens;
  final UserRole role;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      spaceId: data['spaceId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Без имени',
      photoUrl: data['photoUrl'] as String?,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      fcmTokens: List<String>.from(data['fcmTokens'] as List? ?? []),
      role: data['role'] == 'owner' ? UserRole.owner : UserRole.member,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'spaceId': spaceId,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
        'fcmTokens': fcmTokens,
        'role': role == UserRole.owner ? 'owner' : 'member',
      };
}
