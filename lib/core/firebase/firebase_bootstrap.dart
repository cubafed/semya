import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app_check_bootstrap.dart';
import 'firebase_app_holder.dart';
import 'firebase_options_emulator.dart';

const _useEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: true);

bool _emulatorsConnected = false;
Object? _bootstrapError;
Future<bool>? _bootstrapInFlight;
bool _bootstrapDone = false;

bool get isFirebaseBootstrapOk => isFamilyFirebaseReady && _bootstrapError == null;

Object? get firebaseBootstrapError => _bootstrapError;

String get _emulatorHost {
  if (kIsWeb) return 'localhost';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return '10.0.2.2';
    default:
      return 'localhost';
  }
}

Future<bool> bootstrapFirebase() async {
  if (_bootstrapDone && isFamilyFirebaseReady) {
    return isFirebaseBootstrapOk;
  }

  final inFlight = _bootstrapInFlight;
  if (inFlight != null) {
    return inFlight;
  }

  final future = _bootstrapFirebaseOnce();
  _bootstrapInFlight = future;
  try {
    return await future;
  } finally {
    if (identical(_bootstrapInFlight, future)) {
      _bootstrapInFlight = null;
    }
  }
}

Future<bool> _bootstrapFirebaseOnce() async {
  _bootstrapError = null;
  try {
    final options = FirebaseOptionsEmulator.currentPlatform;
    final useLocal = _useEmulators || kDebugMode;

    setFamilyFirebaseApp(await _resolveFamilyFirebaseApp(options));

    if (useLocal) {
      await _connectEmulators();
    } else {
      await activateAppCheckIfNeeded(useEmulators: false);
    }

    _bootstrapDone = true;
    return true;
  } catch (e, st) {
    _bootstrapError = e;
    if (kDebugMode) {
      debugPrint('Firebase bootstrap failed: $e\n$st');
    }
    return false;
  }
}

/// Resolves the [DEFAULT] Firebase app without ever re-configuring native
/// FIRApp. The SIGABRT in `+[FIRApp configureWithName:options:]` /
/// `addAppToAppDictionary` happens when Dart calls `Firebase.initializeApp`
/// while native already has that app. We therefore:
///   1. Reuse anything already registered in Dart.
///   2. Force a native-core sync (no reconfigure) and reuse the native default.
///   3. Only create the default from Dart options if nothing exists at all.
/// We never pass a custom `name` — the named path bypasses the soft duplicate
/// check and raises an Objective-C exception that Dart cannot catch.
Future<FirebaseApp> _resolveFamilyFirebaseApp(FirebaseOptions options) async {
  final preExisting = _findExistingFirebaseApp();
  if (preExisting != null) {
    return preExisting;
  }

  // Triggers MethodChannelFirebase._initializeCore(), which pulls any
  // natively-created apps (e.g. from plugin registration) into the Dart
  // registry. With no GoogleService-Info.plist this throws
  // `core/no-app`/`coreNotInitialized`, which we ignore — the side effect of
  // syncing native apps is what we want.
  try {
    final synced = await Firebase.initializeApp();
    return synced;
  } catch (_) {
    // ignore: native sync may legitimately fail when no default exists.
  }

  final afterSync = _findExistingFirebaseApp();
  if (afterSync != null) {
    return afterSync;
  }

  // Nothing exists anywhere; create the default app from our emulator options.
  return Firebase.initializeApp(options: options);
}

/// Returns any Firebase app already registered in Dart or native (via .app()).
FirebaseApp? _findExistingFirebaseApp() {
  for (final app in Firebase.apps) {
    return app;
  }

  try {
    return Firebase.app();
  } catch (_) {}

  try {
    return Firebase.app(defaultFirebaseAppName);
  } catch (_) {}

  return null;
}

Future<void> _connectEmulators() async {
  if (_emulatorsConnected) return;

  const authPort = 9099;
  const firestorePort = 8080;
  const functionsPort = 5001;
  const storagePort = 9199;
  final host = _emulatorHost;

  try {
    await familyAuth.useAuthEmulator(host, authPort);
  } catch (_) {}

  try {
    familyFirestore.useFirestoreEmulator(host, firestorePort);
  } catch (_) {}

  try {
    familyFunctions.useFunctionsEmulator(host, functionsPort);
  } catch (_) {}

  try {
    await familyStorage.useStorageEmulator(host, storagePort);
  } catch (_) {}

  _emulatorsConnected = true;

  if (kDebugMode) {
    debugPrint('Firebase emulators (${familyFirebaseApp.name}): $host');
  }
}
