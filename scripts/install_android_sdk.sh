#!/bin/bash
# Optional: Android SDK without Android Studio (command-line tools only).
set -euo pipefail

SDK_ROOT="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
mkdir -p "$SDK_ROOT/cmdline-tools"
cd /tmp
curl -o cmdtools.zip https://dl.google.com/android/repository/commandlinetools-mac_arm64-latest.zip
unzip -qo cmdtools.zip -d "$SDK_ROOT/cmdline-tools"
mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
export PATH="$HOME/development/flutter/bin:$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools:$PATH"
yes | sdkmanager --licenses || true
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
flutter config --android-sdk "$SDK_ROOT"
echo "Android SDK installed at $SDK_ROOT"
