import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/invite_join_screen.dart';
import '../../features/auth/presentation/owner_setup_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/contacts/presentation/family_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/settings/presentation/invite_codes_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/calls/presentation/call_screen.dart';
import '../../data/models/app_user.dart';
import '../providers/session_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loc = state.matchedLocation;

      if (session.firebaseUnavailable) return null;

      if (session.isLoading) return null;

      if (!session.isAuthenticated) {
        if (loc == '/' || loc.startsWith('/auth')) return null;
        return '/';
      }

      if (!session.hasProfile) {
        if (loc.startsWith('/auth')) return null;
        return '/auth/join';
      }

      if (loc == '/' || loc.startsWith('/auth')) return '/home/chats';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const AuthGate(),
      ),
      GoRoute(
        path: '/auth/owner',
        builder: (_, __) => const OwnerSetupScreen(),
      ),
      GoRoute(
        path: '/auth/join',
        builder: (_, __) => const InviteJoinScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home/chats',
            builder: (_, __) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/home/family',
            builder: (_, __) => const FamilyScreen(),
          ),
          GoRoute(
            path: '/home/invites',
            builder: (_, __) => const InviteCodesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (_, state) => ChatScreen(
          chatId: state.pathParameters['chatId']!,
        ),
      ),
      GoRoute(
        path: '/home/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/call/:callId',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text('Некорректный звонок')),
            );
          }
          return CallScreen(
            callId: state.pathParameters['callId']!,
            peer: extra['peer'] as AppUser,
            isOutgoing: extra['isOutgoing'] as bool? ?? true,
          );
        },
      ),
    ],
  );
});
