#!/bin/bash
# Открыть проект в Xcode и подсказать запуск на симуляторе iPhone.
set -euo pipefail

export PATH="$HOME/development/flutter/bin:$PATH"
cd "$(dirname "$0")/.."

if [[ "$(pwd)" == *"ШАБОЛДА"* ]]; then
  echo "⚠️  Перейдите в ~/Projects/semya-app"
  exit 1
fi

flutter pub get

# Симулятор Apple (часть Xcode)
if ! xcrun simctl list devices booted 2>/dev/null | grep -q iPhone; then
  open -a Simulator 2>/dev/null || true
fi

WS="ios/Runner.xcworkspace"
if [[ ! -d "$WS" ]]; then
  echo "Нет $WS — выполните: flutter pub get"
  exit 1
fi

open "$WS"
echo ""
echo "Xcode: схема Runner → iPhone Simulator → ⌘R"
echo "Backend: Firebase Emulators (см. README_IOS.md)"
