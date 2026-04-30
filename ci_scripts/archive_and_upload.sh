#!/bin/bash
set -euo pipefail

SCHEME="NerdCourt"
PROJECT="NerdCourt.xcodeproj"
ARCHIVE_PATH="./build/NerdCourt.xcarchive"
EXPORT_PATH="./build/NerdCourt.ipa"
EXPORT_OPTIONS="./build/ExportOptions.plist"

echo "[BUILD] Archiving Nerd Court for TestFlight..."

xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    -configuration Release \
    CODE_SIGN_STYLE=Automatic \
    | xcbeautify

echo "[BUILD] Exporting IPA..."

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    | xcbeautify

echo "[UPLOAD] Uploading to TestFlight..."

xcrun altool --upload-app \
    --type ios \
    --file "$EXPORT_PATH/NerdCourt.ipa" \
    --username "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD"

echo "[DONE] Nerd Court deployed to TestFlight."
