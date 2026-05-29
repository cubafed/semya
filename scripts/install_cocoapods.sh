#!/bin/bash
# CocoaPods for iOS/macOS. Requires administrator password once.
set -euo pipefail

echo "Установка CocoaPods (нужен пароль Mac)..."
sudo gem install cocoapods

export PATH="$HOME/.gem/ruby/$(ruby -e 'puts RUBY_VERSION')/bin:$PATH"
pod --version

PROJECT="${1:-$HOME/Projects/semya}"
export PATH="$HOME/development/flutter/bin:$PATH"

echo "pod install (macOS)..."
cd "$PROJECT/macos" && pod install

echo "pod install (iOS)..."
cd "$PROJECT/ios" && pod install

echo "Готово. Запуск: cd $PROJECT && flutter run -d macos"
