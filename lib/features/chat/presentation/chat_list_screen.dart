import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/session_provider.dart';
import '../../../data/models/chat.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../contacts/presentation/family_screen.dart';

final chatsProvider = StreamProvider.autoDispose<List<Chat>>((ref) {
  final session = ref.watch(sessionProvider);
  final user = session.appUser;
  if (user == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchChatsForUser(
        spaceId: user.spaceId,
        uid: user.uid,
      );
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final chatsAsync = ref.watch(chatsProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final nameByUid = membersAsync.valueOrNull?.fold<Map<String, String>>(
          {},
          (map, u) => map..[u.uid] = u.displayName,
        ) ??
        {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Привет, ${session.appUser?.displayName ?? ''}'),
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Text(
                'Пока нет чатов.\nОткройте вкладку «Семья» и напишите кому-нибудь.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final chat = chats[i];
              final me = session.appUser!.uid;
              final peerUid = chat.members.firstWhere(
                (m) => m != me,
                orElse: () => '',
              );
              final title = chat.type == ChatType.group
                  ? (chat.groupName ?? 'Группа')
                  : (nameByUid[peerUid] ?? 'Чат');
              final preview = chat.lastMessage?.text ?? 'Нет сообщений';
              final time = chat.updatedAt != null
                  ? DateFormat.Hm().format(chat.updatedAt!)
                  : '';

              return ListTile(
                title: Text(title),
                subtitle: Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(time, style: Theme.of(context).textTheme.bodySmall),
                onTap: () => context.push('/chat/${chat.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}
