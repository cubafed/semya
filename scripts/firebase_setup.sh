#!/bin/bash
# Firebase: login, link project, FlutterFire, deploy.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

export PATH="$HOME/development/flutter/bin:$PATH"

echo "1. Вход в Firebase (откроется браузер)..."
npx firebase-tools login

echo "2. Привязка проекта..."
npx firebase-tools use --add

echo "3. FlutterFire (выберите тот же проект)..."
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"
flutterfire configure

echo "4. Раскомментируйте firebase_options в lib/core/firebase/firebase_bootstrap.dart"
echo "5. Deploy rules и functions..."
npx firebase-tools deploy --only functions,firestore:rules,storage,firestore:indexes

echo "Готово."
