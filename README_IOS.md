# iOS: запуск через Xcode (симулятор Apple)

Приложение **Семья** — Flutter-проект. **Симулятор iPhone** — это встроенный **iOS Simulator в Xcode** (не сторонний эмулятор).

Отдельно в терминале нужны только **Firebase Emulators** (локальный Auth/Firestore/Functions на Mac) — это backend для разработки, не замена Xcode.

Рабочая папка: **`~/Projects/semya-app`** (без кириллицы в пути).

---

## Шаг 1. Firebase Emulators (терминал, один раз на сессию)

```bash
export JAVA_HOME="$HOME/development/jdk-21.0.7+6/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
cd ~/Projects/semya-app
cd functions && npm run build && cd ..
npx --yes firebase-tools@13 emulators:start --only auth,firestore,functions,storage --project demo-semya
```

Дождитесь **All emulators ready**.

---

## Шаг 2. Подготовка iOS (терминал)

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd ~/Projects/semya-app
flutter pub get
```

Если Xcode пишет **Missing package product 'FlutterGeneratedPluginSwiftPackage'**:

```bash
bash scripts/fix_ios_xcode.sh
```

---

## Шаг 3. Xcode — симулятор iPhone

```bash
bash scripts/open_xcode.sh
```

В Xcode:

1. Открыт **`ios/Runner.xcworkspace`** (не `.xcodeproj`).
2. Сверху: схема **Runner**, устройство **iPhone 17 Pro** (или любой iPhone Simulator).
3. **Product → Run** (⌘R).

При первом запуске: **Runner → Signing & Capabilities** → **Team** = ваш Apple ID (нужно для Keychain / Firebase Auth; без Team будет `keychain-error`).

Если снова `keychain-error`: **Device → Erase All Content and Settings** в Simulator, затем ⌘R в Xcode.

Секрет владельца в dev: **`dev-local-secret`** (уже по умолчанию при эмуляторах).

---

## CocoaPods

Для **iOS** CocoaPods **не нужен** (Firebase через Swift Package Manager).  
Предупреждение `flutter doctor` про CocoaPods можно игнорировать, если собираете **Runner** на **iPhone Simulator**, а не **My Mac (macOS)**.

---

## Вход в приложении

| Экран | Значение |
|--------|----------|
| Создать пространство | `dev-local-secret` |
| У меня есть код | 8 символов: `node scripts/generate_invite_dev.mjs` + имя |

---

## Альтернатива (тот же симулятор Xcode)

```bash
flutter run -d "iPhone 17 Pro" --dart-define=OWNER_SECRET=dev-local-secret
```

Flutter сам откроет симулятор Apple и соберёт тот же Runner.
