import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_provider.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/chat.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../contacts/presentation/family_screen.dart';

final chatProvider = FutureProvider.autoDispose.family<Chat?, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).getChat(chatId);
});

final chatPeerProvider =
    Provider.autoDispose.family<AppUser?, String>((ref, chatId) {
  final session = ref.watch(sessionProvider);
  final chatAsync = ref.watch(chatProvider(chatId));
  final members = ref.watch(familyMembersProvider);

  final me = session.appUser?.uid;
  final chat = chatAsync.valueOrNull;
  if (me == null || chat == null) return null;

  final peerUid = chat.members.firstWhere(
    (m) => m != me,
    orElse: () => '',
  );
  if (peerUid.isEmpty) return null;

  final list = members.valueOrNull;
  if (list == null) return null;
  for (final u in list) {
    if (u.uid == peerUid) return u;
  }
  return null;
});
