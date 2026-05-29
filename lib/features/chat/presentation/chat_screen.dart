import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../../core/errors/app_errors.dart';
import '../../../data/models/message.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../core/providers/session_provider.dart';
import 'chat_providers.dart';

final messagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _picker = ImagePicker();
  bool _sending = false;
  bool _recording = false;
  String? _playingMessageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final me = ref.read(sessionProvider).appUser?.uid;
    if (me == null) return;
    try {
      await ref.read(chatRepositoryProvider).markMessagesRead(
            chatId: widget.chatId,
            readerId: me,
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final peer = ref.watch(chatPeerProvider(widget.chatId));
    final me = session.appUser?.uid ?? '';
    final title = peer?.displayName ?? 'Чат';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(
              displayName: title,
              photoUrl: peer?.photoUrl,
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Напишите первое сообщение'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == me;
                    final peerRead = msg.readBy.any((id) => id != msg.senderId);
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MessageBody(
                              message: msg,
                              playingId: _playingMessageId,
                              onPlayVoice: () => _playVoice(msg),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat.Hm().format(msg.createdAt),
                                  style:
                                      Theme.of(context).textTheme.labelSmall,
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    peerRead
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 14,
                                    color: peerRead
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                        : null,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(friendlyErrorMessage(e)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _toggleRecord,
                    icon: Icon(
                      _recording ? Icons.stop_circle : Icons.mic_none,
                      color: _recording ? Colors.red : null,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Сообщение…',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendText(me),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : () => _sendText(me),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      _showError('Фото на веб пока недоступны');
      return;
    }
    final me = ref.read(sessionProvider).appUser?.uid;
    if (me == null) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() => _sending = true);
      final url = await ref.read(storageRepositoryProvider).uploadChatImage(
            chatId: widget.chatId,
            file: File(file.path),
          );
      await ref.read(chatRepositoryProvider).sendImageMessage(
            chatId: widget.chatId,
            senderId: me,
            mediaUrl: url,
          );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleRecord() async {
    if (kIsWeb) {
      _showError('Голосовые на веб пока недоступны');
      return;
    }
    final me = ref.read(sessionProvider).appUser?.uid;
    if (me == null) return;

    if (_recording) {
      setState(() => _recording = false);
      try {
        final path = await _audioRecorder.stop();
        if (path == null) return;
        setState(() => _sending = true);
        final file = File(path);
        final url = await ref.read(storageRepositoryProvider).uploadVoiceMessage(
              chatId: widget.chatId,
              file: file,
            );
        final duration = await _probeDuration(path);
        await ref.read(chatRepositoryProvider).sendVoiceMessage(
              chatId: widget.chatId,
              senderId: me,
              mediaUrl: url,
              durationMs: duration,
            );
      } catch (e) {
        _showError(e);
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }

    if (!await _audioRecorder.hasPermission()) {
      _showError('Нет доступа к микрофону');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() => _recording = true);
  }

  Future<int> _probeDuration(String path) async {
    try {
      final player = AudioPlayer();
      await player.setFilePath(path);
      final d = player.duration ?? Duration.zero;
      await player.dispose();
      return d.inMilliseconds.clamp(500, 600000);
    } catch (_) {
      return 1000;
    }
  }

  Future<void> _playVoice(ChatMessage msg) async {
    final url = msg.mediaUrl;
    if (url == null) return;
    setState(() => _playingMessageId = msg.id);
    try {
      final player = AudioPlayer();
      await player.setUrl(url);
      await player.play();
      await player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
      await player.dispose();
    } catch (_) {}
    if (mounted) setState(() => _playingMessageId = null);
  }

  Future<void> _sendText(String senderId) async {
    final text = _controller.text.trim();
    if (text.isEmpty || senderId.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).sendTextMessage(
            chatId: widget.chatId,
            senderId: senderId,
            text: text,
          );
      _controller.clear();
      await _markRead();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(friendlyErrorMessage(e))),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.message,
    required this.playingId,
    required this.onPlayVoice,
  });

  final ChatMessage message;
  final String? playingId;
  final VoidCallback onPlayVoice;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        final url = message.mediaUrl;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text('Не удалось загрузить фото'),
                ),
              ),
            if (message.text != null && message.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(message.text!),
              ),
          ],
        );
      case MessageType.voice:
        final sec = ((message.durationMs ?? 0) / 1000).round();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPlayVoice,
              icon: Icon(
                playingId == message.id
                    ? Icons.pause_circle
                    : Icons.play_circle,
              ),
            ),
            Text('Голосовое · ${sec}s'),
          ],
        );
      case MessageType.text:
      case MessageType.video:
        return Text(message.text ?? '');
    }
  }
}
