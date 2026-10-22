#!/usr/bin/env bash
# Notarizes and staples build/LookUp.app.
# Needs APPLE_ID, APPLE_TEAM_ID and APPLE_APP_PASSWORD (an app-specific password).
set -euo pipefail

cd "$(dirname "$0")/.."

app="build/LookUp.app"
archive="build/LookUp-notarization.zip"

ditto -c -k --keepParent "$app" "$archive"
xcrun notarytool submit "$archive" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait
xcrun stapler staple "$app"
rm "$archive"
