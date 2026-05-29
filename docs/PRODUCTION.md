# Подготовка к продакшену

## 1. Firebase-проект

1. Создайте проект в [Firebase Console](https://console.firebase.google.com).
2. Включите **Anonymous Auth**, **Firestore**, **Storage**, **Cloud Functions**.
3. Локально: `flutterfire configure` и подключите `lib/firebase_options.dart` в `firebase_bootstrap.dart` (вместо только emulator options).

## 2. Секреты

- Задайте `OWNER_SECRET` в Secret Manager / CI, не в git.
- В `firebase.json` уберите dev-секрет или используйте deploy-only env.
- Запуск: `--dart-define=OWNER_SECRET=...` и `--dart-define=USE_EMULATORS=false`.

## 3. App Check

В Console включите App Check для iOS/Android/Web. В коде раскомментируйте активацию в `lib/core/firebase/app_check_bootstrap.dart`.

## 4. Push (APNs)

- Apple Developer: ключ APNs → Firebase → Cloud Messaging.
- Xcode: Push Notifications capability, Background Modes → Remote notifications.
- На симуляторе push ограничены; тестируйте на устройстве.

## 5. Деплой

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

## 6. iOS релиз

- Иконка и Launch Screen в `ios/Runner/Assets.xcassets`.
- `flutter build ipa` или Archive в Xcode.
- Проверьте **Signing & Capabilities** (Team, Keychain, Push).
