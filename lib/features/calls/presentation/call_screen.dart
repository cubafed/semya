import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/session_provider.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/call_repository.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({
    super.key,
    required this.callId,
    required this.peer,
    required this.isOutgoing,
  });

  final String callId;
  final AppUser peer;
  final bool isOutgoing;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _initialized = false;
  StreamSubscription? _callSub;
  StreamSubscription? _iceSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    final me = ref.read(sessionProvider).appUser?.uid;
    if (me == null) return;

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _pc = await createPeerConnection(config);
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
      }
    };

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      ref.read(callRepositoryProvider).addIceCandidate(
            widget.callId,
            candidate.toMap(),
          );
    };

    _iceSub = ref.read(callRepositoryProvider).watchIceCandidates(widget.callId).listen(
      (candidates) async {
        for (final c in candidates) {
          try {
            await _pc!.addCandidate(
              RTCIceCandidate(
                c['candidate'] as String?,
                c['sdpMid'] as String?,
                c['sdpMLineIndex'] as int?,
              ),
            );
          } catch (_) {}
        }
      },
    );

    if (widget.isOutgoing) {
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      await ref.read(callRepositoryProvider).setOffer(
            widget.callId,
            {'type': offer.type, 'sdp': offer.sdp},
          );
    }

    _callSub = ref.read(callRepositoryProvider).watchCall(widget.callId).listen(
      (call) async {
        if (call == null || _pc == null) return;
        if (call.answer != null && _pc!.signalingState != RTCSignalingState.RTCSignalingStateStable) {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(
              call.answer!['sdp'] as String?,
              call.answer!['type'] as String?,
            ),
          );
        }
        if (call.status == CallStatus.ended || call.status == CallStatus.missed) {
          if (mounted) context.pop();
        }
      },
    );

    setState(() => _initialized = true);
  }

  Future<void> _hangUp() async {
    await ref.read(callRepositoryProvider).endCall(widget.callId);
    if (mounted) context.pop();
  }

  Future<void> _answer() async {
    final call = await ref.read(callRepositoryProvider).watchCall(widget.callId).first;
    if (call?.offer == null || _pc == null) return;
    await _pc!.setRemoteDescription(
      RTCSessionDescription(
        call!.offer!['sdp'] as String?,
        call.offer!['type'] as String?,
      ),
    );
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await ref.read(callRepositoryProvider).setAnswer(
          widget.callId,
          {'type': answer.type, 'sdp': answer.sdp},
        );
  }

  @override
  void dispose() {
    _callSub?.cancel();
    _iceSub?.cancel();
    _localStream?.dispose();
    _pc?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Text(
              widget.peer.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isOutgoing ? 'Звоним…' : 'Входящий звонок',
              style: const TextStyle(color: Colors.white70),
            ),
            const Spacer(),
            if (!_initialized)
              const CircularProgressIndicator(color: Colors.white),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!widget.isOutgoing)
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.all(20),
                    ),
                    onPressed: _answer,
                    icon: const Icon(Icons.call, color: Colors.white),
                  ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(20),
                  ),
                  onPressed: _hangUp,
                  icon: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
