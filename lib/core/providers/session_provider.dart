import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

class SessionState {
  const SessionState({
    this.isLoading = true,
    this.firebaseUser,
    this.appUser,
  });

  final bool isLoading;
  final User? firebaseUser;
  final AppUser? appUser;

  bool get isAuthenticated => firebaseUser != null;
  bool get hasProfile => appUser != null && appUser!.spaceId.isNotEmpty;
  bool get isOwner => appUser?.role == UserRole.owner;
}

final sessionProvider =
    NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);

class SessionNotifier extends Notifier<SessionState> {
  StreamSubscription<User?>? _authSub;

  @override
  SessionState build() {
    final authRepo = ref.watch(authRepositoryProvider);
    final userRepo = ref.watch(userRepositoryProvider);

    _authSub?.cancel();
    _authSub = authRepo.authStateChanges().listen((user) {
      unawaited(_onAuthUser(user, userRepo));
    });

    ref.onDispose(() => _authSub?.cancel());

    return const SessionState(isLoading: true);
  }

  Future<void> _onAuthUser(User? user, UserRepository userRepo) async {
    if (user == null) {
      state = const SessionState(isLoading: false);
      return;
    }
    state = SessionState(isLoading: true, firebaseUser: user);
    final profile = await userRepo.getUser(user.uid);
    state = SessionState(
      isLoading: false,
      firebaseUser: user,
      appUser: profile,
    );
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
