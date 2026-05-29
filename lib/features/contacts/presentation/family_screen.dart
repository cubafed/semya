import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_errors.dart';
import '../../../core/providers/session_provider.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/widgets/user_avatar.dart';

final familyMembersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final spaceId = ref.watch(sessionProvider).appUser?.spaceId;
  if (spaceId == null || spaceId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(userRepositoryProvider).watchSpaceMembers(spaceId);
});

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final me = session.appUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Семья')),
      body: membersAsync.when(
        data: (members) {
          final others = members.where((m) => m.uid != me?.uid).toList();
          if (others.isEmpty) {
            return const Center(
              child: Text('Пока только вы.\nВыдайте коды приглашения родным.'),
            );
          }
          return ListView.builder(
            itemCount: others.length,
            itemBuilder: (context, i) {
              final member = others[i];
              return ListTile(
                leading: UserAvatar(
                  displayName: member.displayName,
                  photoUrl: member.photoUrl,
                ),
                title: Text(member.displayName),
                subtitle: Text(
                  member.role == UserRole.owner ? 'Владелец' : 'Участник',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call_outlined),
                      onPressed: () => _startCall(context, ref, member),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_outlined),
                      onPressed: () => _openChat(context, ref, member),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
      ),
    );
  }

  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    AppUser peer,
  ) async {
    final me = ref.read(sessionProvider).appUser;
    if (me == null) return;

    try {
      final chatId = await ref.read(chatRepositoryProvider).getOrCreateDirectChat(
            spaceId: me.spaceId,
            myUid: me.uid,
            peerUid: peer.uid,
          );
      if (context.mounted) context.push('/chat/$chatId');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _startCall(
    BuildContext context,
    WidgetRef ref,
    AppUser peer,
  ) async {
    final me = ref.read(sessionProvider).appUser;
    if (me == null) return;

    try {
      final callId = await ref.read(callRepositoryProvider).createOutgoingCall(
            callerId: me.uid,
            calleeId: peer.uid,
          );
      if (context.mounted) {
        context.push(
          '/call/$callId',
          extra: {'peer': peer, 'isOutgoing': true},
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }
}
