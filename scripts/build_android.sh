#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter is missing from PATH. See START_HERE_URDU.md or README.md.' >&2
  exit 1
fi
if [ ! -f config.json ] && [ -f config.public.json ]; then
  cp config.public.json config.json
fi
test -f config.json || { echo 'Copy config.example.json to config.json and enter public configuration.'; exit 1; }
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config.json
echo 'Built: build/app/outputs/flutter-apk/app-debug.apk'
