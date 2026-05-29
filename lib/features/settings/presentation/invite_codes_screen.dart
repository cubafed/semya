import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/invite_repository.dart';

class InviteCodesScreen extends ConsumerStatefulWidget {
  const InviteCodesScreen({super.key});

  @override
  ConsumerState<InviteCodesScreen> createState() => _InviteCodesScreenState();
}

class _InviteCodesScreenState extends ConsumerState<InviteCodesScreen> {
  List<Map<String, dynamic>> _invites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ref.read(inviteRepositoryProvider).listInvites();
      if (mounted) setState(() => _invites = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    try {
      final code = await ref.read(inviteRepositoryProvider).generateInvite();
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Код $code скопирован')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Коды приглашения')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generate,
        icon: const Icon(Icons.add),
        label: const Text('Новый код'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invites.isEmpty
              ? const Center(
                  child: Text('Создайте код и отправьте родственнику'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _invites.length,
                    itemBuilder: (context, i) {
                      final inv = _invites[i];
                      final used = inv['usedBy'] != null;
                      return ListTile(
                        title: Text(inv['code'] as String? ?? ''),
                        subtitle: Text(
                          used ? 'Использован' : 'Активен до ${inv['expiresAt']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: inv['code'] as String),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
