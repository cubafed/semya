#!/bin/bash
# Восстановление iOS после flutter clean / ошибки FlutterGeneratedPluginSwiftPackage (SPM, без CocoaPods).
set -euo pipefail

export PATH="$HOME/development/flutter/bin:$PATH"
cd "$(dirname "$0")/.."

if [[ "$(pwd)" == *"ШАБОЛДА"* ]]; then
  echo "⚠️  Используйте ~/Projects/semya-app — кириллица в пути ломает Xcode/SPM."
  exit 1
fi

echo "→ flutter clean && flutter pub get"
flutter clean
flutter pub get

echo "→ Сборка для симулятора (генерирует ephemeral SPM-пакет)"
flutter build ios --simulator --no-codesign

echo ""
echo "✓ Готово. Откройте Xcode:"
echo "  open ios/Runner.xcworkspace"
echo ""
echo "В Xcode: iPhone Simulator → Product → Run (⌘R)"
echo "Firebase Emulators — в отдельном терминале (см. README_IOS.md)"
