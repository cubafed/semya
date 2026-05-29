#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/development/flutter}"

echo "==> Flutter SDK"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
grep -q 'development/flutter/bin' "$HOME/.zshrc" 2>/dev/null || \
  echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> "$HOME/.zshrc"

flutter config --no-enable-swift-package-manager
cd "$PROJECT_DIR"
flutter pub get

echo "==> Cloud Functions"
cd "$PROJECT_DIR/functions"
npm install
npm run build

echo "==> Firebase CLI (local npx, no global install)"
cd "$PROJECT_DIR"
npx firebase-tools --version

echo ""
echo "Готово локально. Дальше вручную (нужен ваш Google-аккаунт):"
echo "  1. npx firebase-tools login"
echo "  2. npx firebase-tools use --add"
echo "  3. dart pub global activate flutterfire_cli && flutterfire configure"
echo "  4. npx firebase-tools deploy --only functions,firestore:rules,storage"
echo ""
echo "Запуск (после Firebase):"
echo "  flutter run -d macos --dart-define=OWNER_SECRET=ваш-секрет"
