import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

FirebaseApp? _familyFirebaseApp;

bool get isFamilyFirebaseReady => _familyFirebaseApp != null;

void setFamilyFirebaseApp(FirebaseApp app) {
  _familyFirebaseApp = app;
}

FirebaseApp get familyFirebaseApp {
  final app = _familyFirebaseApp;
  if (app == null) {
    throw StateError(
      'Firebase не инициализирован. Вызовите bootstrapFirebase() до использования.',
    );
  }
  return app;
}

FirebaseAuth get familyAuth => FirebaseAuth.instanceFor(app: familyFirebaseApp);

FirebaseFirestore get familyFirestore =>
    FirebaseFirestore.instanceFor(app: familyFirebaseApp);

FirebaseFunctions get familyFunctions =>
    FirebaseFunctions.instanceFor(app: familyFirebaseApp);

FirebaseStorage get familyStorage =>
    FirebaseStorage.instanceFor(app: familyFirebaseApp);
