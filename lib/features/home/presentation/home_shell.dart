import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  int _indexFromLocation(String location, bool isOwner) {
    if (location.contains('/family')) return 1;
    if (isOwner && location.contains('/invites')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final isOwner = session.isOwner;
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location, isOwner);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home/chats');
            case 1:
              context.go('/home/family');
            case 2:
              if (session.isOwner) context.go('/home/invites');
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Чаты',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Семья',
          ),
          if (session.isOwner)
            const NavigationDestination(
              icon: Icon(Icons.vpn_key_outlined),
              selectedIcon: Icon(Icons.vpn_key),
              label: 'Коды',
            ),
        ],
      ),
    );
  }
}
