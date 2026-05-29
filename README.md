# Семейный мессенджер

Приватный мессенджер для семьи: чаты, медиа (в разработке), голосовые звонки (в разработке).  
Вход по **invite-коду**, без номера телефона.

## Стек

- Flutter + Riverpod + go_router
- Firebase: Auth (Anonymous), Firestore, Storage, Cloud Functions, FCM

## Быстрый старт

### 1. Flutter

```bash
cd "/Users/daviddaler/Documents/ШАБОЛДА"
flutter create . --org com.family --project-name family_messenger
flutter pub get
```

### 2. Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) → новый проект.
2. Включить **Anonymous Auth** в Authentication.
3. Создать Firestore и Storage.
4. Установить CLI: `npm i -g firebase-tools` → `firebase login`.
5. `firebase use --add` в корне проекта.
6. FlutterFire:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Раскомментируйте в `lib/core/firebase/firebase_bootstrap.dart` импорт `firebase_options.dart`.

### 3. Cloud Functions

```bash
cd functions
npm install
npm run build
cd ..
firebase functions:config:set owner.secret="ВАШ-СЕКРЕТ"
```

Задайте тот же секрет в Flutter:

```bash
flutter run --dart-define=OWNER_SECRET=ВАШ-СЕКРЕТ
```

Или измените `AppConstants.ownerBootstrapSecret` / переменную `OWNER_SECRET` в Functions.

```bash
firebase deploy --only functions,firestore:rules,storage,firestore:indexes
```

### 4. Первый запуск

1. **Владелец:** «Создать семейное пространство» → секрет → название семьи → имя.
2. Вкладка **Коды** → «Новый код» → отправить родственнику.
3. **Родственник:** «У меня есть код» → код + имя → вкладка **Семья** → написать.

### Эмуляторы (локальная разработка)

```bash
firebase emulators:start
flutter run --dart-define=USE_EMULATORS=true
```

(Подключение эмуляторов в коде можно добавить в `firebase_bootstrap.dart` при необходимости.)

## Структура

```
lib/
  core/          тема, роутер, сессия
  data/          модели и репозитории
  features/
    auth/        invite + владелец
    chat/        список и экран чата
    contacts/    семья
    settings/    коды приглашения
functions/       createSpaceAsOwner, redeemInvite, generateInvite
```

## Что уже есть / что дальше

| Готово | В плане |
|--------|---------|
| Anonymous Auth + invite-коды | Push (FCM + Functions) |
| 1-на-1 текстовые чаты | Фото/видео, голосовые |
| Список семьи | WebRTC звонки |
| Firestore rules | Группы, App Check в prod |

## Безопасность

- Смените `OWNER_SECRET` перед релизом.
- Включите App Check в Firebase Console для production.
- Invite-коды одноразовые, TTL 72 часа (настраивается в `generateInvite`).
