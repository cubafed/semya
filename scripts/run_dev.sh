#!/bin/bash
# Локальный запуск: Firebase Emulators + Flutter (Chrome).
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/development/flutter/bin:$PATH"
export JAVA_HOME="${JAVA_HOME:-$HOME/development/jdk-21.0.7+6/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"

cd "$PROJECT_DIR"

echo "==> Сборка Cloud Functions..."
(cd functions && npm run build)

echo "==> Запуск Firebase Emulators..."
npx firebase-tools emulators:start \
  --only auth,firestore,functions,storage \
  --project demo-semya &
EMU_PID=$!

cleanup() {
  kill "$EMU_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "Ждём эмуляторы (15 сек)..."
sleep 15

echo "==> Flutter (Chrome)..."
echo "    UI эмуляторов: http://localhost:4000"
echo "    Секрет владельца: dev-local-secret"
echo ""

flutter run -d chrome \
  --dart-define=USE_EMULATORS=true \
  --dart-define=OWNER_SECRET=dev-local-secret \
  --no-devtools
