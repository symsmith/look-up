#!/usr/bin/env bash
# Zips build/LookUp.app into build/LookUp-<version>.zip and writes its SHA-256 next to it.
set -euo pipefail

cd "$(dirname "$0")/.."

app="build/LookUp.app"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
archive="build/LookUp-$version.zip"

rm -f "$archive" "$archive.sha256"
ditto -c -k --keepParent "$app" "$archive"
(cd build && shasum -a 256 "$(basename "$archive")" > "$(basename "$archive").sha256")

echo "$archive"
