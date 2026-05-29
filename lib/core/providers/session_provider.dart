import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_bootstrap.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

class SessionState {
  const SessionState({
    this.isLoading = true,
    this.firebaseUser,
    this.appUser,
    this.firebaseUnavailable = false,
  });

  final bool isLoading;
  final User? firebaseUser;
  final AppUser? appUser;
  final bool firebaseUnavailable;

  bool get isAuthenticated => firebaseUser != null;
  bool get hasProfile => appUser != null && appUser!.spaceId.isNotEmpty;
  bool get isOwner => appUser?.role == UserRole.owner;
}

final sessionProvider =
    NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);

class SessionNotifier extends Notifier<SessionState> {
  StreamSubscription<User?>? _authSub;
  Timer? _loadingTimeout;

  @override
  SessionState build() {
    if (!isFirebaseBootstrapOk) {
      return const SessionState(
        isLoading: false,
        firebaseUnavailable: true,
      );
    }

    final authRepo = ref.watch(authRepositoryProvider);
    final userRepo = ref.watch(userRepositoryProvider);

    _authSub?.cancel();
    _loadingTimeout?.cancel();

    final existingUser = authRepo.currentUser;
    if (existingUser != null) {
      unawaited(_onAuthUser(existingUser, userRepo));
    }

    _authSub = authRepo.authStateChanges().listen(
      (user) => unawaited(_onAuthUser(user, userRepo)),
      onError: (_) {
        state = const SessionState(isLoading: false);
      },
    );

    _loadingTimeout = Timer(const Duration(seconds: 5), () {
      if (state.isLoading && state.firebaseUser == null) {
        state = const SessionState(isLoading: false);
      }
    });

    ref.onDispose(() {
      _authSub?.cancel();
      _loadingTimeout?.cancel();
    });

    return const SessionState(isLoading: true);
  }

  Future<void> _onAuthUser(User? user, UserRepository userRepo) async {
    _loadingTimeout?.cancel();
    if (user == null) {
      state = const SessionState(isLoading: false);
      return;
    }
    state = SessionState(isLoading: true, firebaseUser: user);
    try {
      final profile = await userRepo
          .getUser(user.uid)
          .timeout(const Duration(seconds: 8));
      state = SessionState(
        isLoading: false,
        firebaseUser: user,
        appUser: profile,
      );
    } catch (_) {
      state = SessionState(isLoading: false, firebaseUser: user);
    }
  }

  Future<void> refreshProfile() async {
    final uid = state.firebaseUser?.uid;
    if (uid == null) return;
    final profile = await ref.read(userRepositoryProvider).getUser(uid);
    state = SessionState(
      isLoading: false,
      firebaseUser: state.firebaseUser,
      appUser: profile,
    );
  }
}
