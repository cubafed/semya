import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options_emulator.dart';

const _useEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: true);

String get _emulatorHost {
  if (kIsWeb) return 'localhost';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return '10.0.2.2';
    default:
      return 'localhost';
  }
}

Future<void> bootstrapFirebase() async {
  if (Firebase.apps.isNotEmpty) return;

  // Production: after `flutterfire configure`, replace with:
  // import '../../firebase_options.dart';
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final useLocal = _useEmulators || kDebugMode;

  if (useLocal) {
    await Firebase.initializeApp(
      options: FirebaseOptionsEmulator.currentPlatform,
    );
    await _connectEmulators();
    return;
  }

  await Firebase.initializeApp();
}

Future<void> _connectEmulators() async {
  const authPort = 9099;
  const firestorePort = 8080;
  const functionsPort = 5001;
  const storagePort = 9199;

  final host = _emulatorHost;

  await FirebaseAuth.instance.useAuthEmulator(host, authPort);
  FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
  FirebaseFunctions.instance.useFunctionsEmulator(host, functionsPort);
  await FirebaseStorage.instance.useStorageEmulator(host, storagePort);

  if (kDebugMode) {
    debugPrint('Firebase emulators: $host (auth $authPort, firestore $firestorePort)');
  }
}
