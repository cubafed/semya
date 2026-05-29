import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Demo Firebase config for local emulators only (not production).
///
/// iOS validates [appId] format strictly (`1:sender:ios:hex`), so placeholder
/// values like `:emulator` crash native Firebase before Dart UI renders.
class FirebaseOptionsEmulator {
  FirebaseOptionsEmulator._();

  static const String projectId = 'demo-semya';
  static const String messagingSenderId = '000000000000';
  static const String apiKey = 'AIzaSy000000000000000000000000000000000';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
    storageBucket: '$projectId.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
    iosBundleId: 'com.family.familyMessenger',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
    iosBundleId: 'com.family.familyMessenger',
  );
}
