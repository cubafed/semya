# Семейный мессенджер

Приватный мессенджер для семьи: чаты, медиа (в разработке), голосовые звонки (в разработке).  
Вход по **invite-коду**, без номера телефона.

## Стек

- Flutter + Riverpod + go_router
- Firebase: Auth (Anonymous), Firestore, Storage, Cloud Functions, FCM

## Быстрый старт

> **Путь без кириллицы:** работайте из `~/Projects/semya` (симлинк на этот проект).

### Запуск за одну команду (локально, без Firebase Console)

Уже установлены: Flutter, Java (для эмуляторов), демо-проект `demo-semya`.

```bash
bash ~/Projects/semya/scripts/run_dev.sh
```

Откроется Chrome. Секрет владельца: **`dev-local-secret`**. UI эмуляторов: http://localhost:4000

Ошибки `AppInspector` / `Cannot find context` в IDE — безвредны; скрипт запускает с `--no-devtools`.

### 1. Flutter (уже установлен на этом Mac)

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd ~/Projects/semya
flutter pub get
```

Если Flutter ещё нет: `bash scripts/setup.sh`

### 2. CocoaPods (для iPhone / Mac — один раз, нужен пароль)

```bash
bash scripts/install_cocoapods.sh
```

### 3. Firebase (нужен ваш Google-аккаунт)

```bash
bash scripts/firebase_setup.sh
```

Или вручную: Anonymous Auth + Firestore + Storage в [Firebase Console](https://console.firebase.google.com), затем `flutterfire configure` и раскомментируйте `firebase_options` в `lib/core/firebase/firebase_bootstrap.dart`.

### 4. Cloud Functions (уже собраны локально)

```bash
cd functions && npm install && npm run build && cd ..
npx firebase-tools deploy --only functions,firestore:rules,storage,firestore:indexes
```

Секрет владельца — в `firebase.json` → `OWNER_SECRET` и при запуске:

```bash
flutter run -d macos --dart-define=OWNER_SECRET=ВАШ-СЕКРЕТ
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

## Что уже есть

| Функция | Статус |
|---------|--------|
| Anonymous Auth + invite-коды | Готово |
| 1-на-1 текстовые чаты + превью | Готово |
| Статусы прочтения (галочки) | Готово |
| Аватары (Storage) | Готово |
| Фото и голосовые в чате | Готово (iOS/Android; на iOS нужен CocoaPods для плагинов) |
| Push FCM (`onChatMessageCreated`) | Готово (на устройстве + APNs) |
| WebRTC аудио-звонки (базово) | Готово |
| Продакшен-чеклист | [docs/PRODUCTION.md](docs/PRODUCTION.md) |

## Безопасность

- Смените `OWNER_SECRET` перед релизом.
- Включите App Check в Firebase Console для production.
- Invite-коды одноразовые, TTL 72 часа (настраивается в `generateInvite`).
