import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_errors.dart';
import '../../../core/providers/session_provider.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/widgets/user_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_nameController.text.isEmpty) {
      _nameController.text = user.displayName;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: UserAvatar(
                displayName: user.displayName,
                photoUrl: user.photoUrl,
                radius: 48,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Нажмите, чтобы сменить фото'),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _saveName,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить имя'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final uid = ref.read(sessionProvider).appUser?.uid;
    if (uid == null) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() => _saving = true);
      final url = await ref.read(storageRepositoryProvider).uploadAvatar(
            uid: uid,
            file: File(file.path),
          );
      await ref.read(userRepositoryProvider).updatePhotoUrl(uid, url);
      await ref.read(sessionProvider.notifier).refreshProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveName() async {
    final uid = ref.read(sessionProvider).appUser?.uid;
    final name = _nameController.text.trim();
    if (uid == null || name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateDisplayName(uid, name);
      await ref.read(sessionProvider.notifier).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Имя сохранено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
