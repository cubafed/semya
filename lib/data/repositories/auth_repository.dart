import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_app_holder.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(familyAuth);
});

class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      // iOS Simulator: stale keychain after reinstall — retry once after signOut.
      if (e.code == 'keychain-error') {
        try {
          await _auth.signOut();
        } catch (_) {}
        return _auth.signInAnonymously();
      }
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();
}
