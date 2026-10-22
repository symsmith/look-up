#!/usr/bin/env bash
# Builds build/LookUp.app as a universal binary.
# VERSION and BUILD_NUMBER override the Info.plist values.
# CODESIGN_IDENTITY selects a Developer ID identity; the default "-" signs ad hoc.
set -euo pipefail

cd "$(dirname "$0")/.."

version="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)}"
build_number="${BUILD_NUMBER:-1}"
identity="${CODESIGN_IDENTITY:--}"
app="build/LookUp.app"
swift_flags=(-c release --arch arm64 --arch x86_64)

swift build "${swift_flags[@]}"
bin_path="$(swift build "${swift_flags[@]}" --show-bin-path)"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_path/LookUp" "$app/Contents/MacOS/LookUp"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy \
    -c "Set :CFBundleShortVersionString $version" \
    -c "Set :CFBundleVersion $build_number" \
    "$app/Contents/Info.plist"

if [[ "$identity" == "-" ]]; then
    codesign --force --sign - "$app"
else
    codesign --force --options runtime --timestamp --sign "$identity" "$app"
fi
codesign --verify --strict "$app"

echo "$app"
