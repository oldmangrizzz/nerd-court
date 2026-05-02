#!/bin/bash
set -euo pipefail

echo "[CI] Nerd Court — post-clone setup"

# Xcode Cloud already has xcodegen at /opt/homebrew/bin/xcodegen; fall back to brew only if missing.
if ! command -v xcodegen &> /dev/null; then
    brew install xcodegen
fi

# Generate Xcode project from spec
xcodegen generate --spec project.yml

echo "[CI] Xcode project generated."

# Resolve placeholders in ExportOptions template if present
if [[ -f "ci_scripts/ExportOptions.plist.template" ]]; then
    mkdir -p build
    sed -e "s|JARVIS_DEV_TEAM|${JARVIS_DEV_TEAM:-}|g" \
        ci_scripts/ExportOptions.plist.template > build/ExportOptions.plist
    echo "[CI] ExportOptions.plist generated."
fi
