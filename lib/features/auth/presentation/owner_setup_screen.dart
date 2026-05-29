import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_errors.dart';
import '../../../core/providers/session_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/invite_repository.dart';

class OwnerSetupScreen extends ConsumerStatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  ConsumerState<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends ConsumerState<OwnerSetupScreen> {
  final _secretController = TextEditingController();
  final _spaceController = TextEditingController(text: 'Наша семья');
  final _nameController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _secretController.dispose();
    _spaceController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создать пространство')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              'Только для первого запуска. Секрет задаётся в коде или через '
              '--dart-define=OWNER_SECRET=...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _secretController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Секрет владельца'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _spaceController,
              decoration: const InputDecoration(
                labelText: 'Название семьи',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ваше имя'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final secret = _secretController.text.trim();
    final spaceName = _spaceController.text.trim();
    final name = _nameController.text.trim();

    if (secret != AppConstants.ownerBootstrapSecret) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный секрет владельца')),
      );
      return;
    }
    if (spaceName.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
      await ref.read(inviteRepositoryProvider).createSpaceAsOwner(
            ownerSecret: secret,
            spaceName: spaceName,
            displayName: name,
          );
      await ref.read(sessionProvider.notifier).refreshProfile();
      if (mounted) context.go('/home/chats');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
