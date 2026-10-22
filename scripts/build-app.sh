#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release
bin_path="$(swift build -c release --show-bin-path)"
app="build/LookUp.app"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_path/LookUp" "$app/Contents/MacOS/LookUp"
cp Resources/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"

echo "$app"
