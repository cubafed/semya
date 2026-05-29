import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/session_provider.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    if (session.firebaseUnavailable) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Firebase недоступен. Запустите эмуляторы и перезапустите приложение.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (session.isLoading || _starting) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.family_restroom,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Семейный мессенджер',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Только для своих. Вход по коду приглашения.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _starting ? null : () => _enterWithInvite(context),
                child: const Text('У меня есть код'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/auth/owner'),
                child: const Text('Создать семейное пространство'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enterWithInvite(BuildContext context) async {
    setState(() => _starting = true);
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
      if (context.mounted) context.push('/auth/join');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка входа: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }
}
