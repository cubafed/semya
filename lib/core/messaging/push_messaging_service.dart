import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_repository.dart';
import '../providers/session_provider.dart';

/// Background handler must be top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

final pendingChatRouteProvider = StateProvider<String?>((ref) => null);

class PushMessagingService {
  PushMessagingService(this._ref);

  final Ref _ref;
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await _syncToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _saveToken(token);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessage(initial);
  }

  Future<void> _syncToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('FCM token: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = _ref.read(sessionProvider).firebaseUser?.uid;
    if (uid == null) return;
    await _ref.read(userRepositoryProvider).addFcmToken(uid, token);
  }

  void _handleMessage(RemoteMessage message) {
    final chatId = message.data['chatId'];
    if (chatId != null && chatId.isNotEmpty) {
      _ref.read(pendingChatRouteProvider.notifier).state = '/chat/$chatId';
    }
  }
}

final pushMessagingServiceProvider = Provider<PushMessagingService>((ref) {
  return PushMessagingService(ref);
});
