import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// После `flutterfire configure` раскомментируйте:
// import '../../firebase_options.dart';

Future<void> bootstrapFirebase() async {
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (Firebase.apps.isEmpty) {
    if (kIsWeb) {
      throw FlutterError(
        'Firebase не настроен. Выполните: dart pub global activate flutterfire_cli && flutterfire configure',
      );
    }
    await Firebase.initializeApp();
  }

  if (kDebugMode) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } catch (_) {
      // App Check опционален на этапе разработки без консоли Firebase.
    }
  }
}
