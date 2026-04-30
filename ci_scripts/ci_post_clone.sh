#!/bin/bash
set -euo pipefail

echo "[CI] Nerd Court — post-clone setup"

# Install xcodegen if not present
if ! command -v xcodegen &> /dev/null; then
    brew install xcodegen
fi

# Generate Xcode project
xcodegen generate --spec project.yml

echo "[CI] Xcode project generated."
