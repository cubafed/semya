import 'package:flutter/foundation.dart';

/// App Check for production. Enable after registering apps in Firebase Console.
Future<void> activateAppCheckIfNeeded({required bool useEmulators}) async {
  if (useEmulators || kDebugMode) {
    return;
  }
  // Example (uncomment when firebase_app_check is added):
  // await FirebaseAppCheck.instance.activate(
  //   appleProvider: AppleProvider.appAttest,
  //   androidProvider: AndroidProvider.playIntegrity,
  // );
  debugPrint('App Check: configure in Firebase Console before release.');
}
