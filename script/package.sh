#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
BUILD_CONFIGURATION=release ./script/build_and_run.sh --build
mkdir -p artifacts
STAGE_DIR="$(mktemp -d /private/tmp/simstation-package.XXXXXX)"
mkdir -p "$STAGE_DIR/image" "$STAGE_DIR/source/SIM-Station/Sources"
ditto --norsrc --noextattr --noqtn 'dist/SIM Station.app' "$STAGE_DIR/image/SIM Station.app"
cp README.md "$STAGE_DIR/image/使用说明.md"
ln -s /Applications "$STAGE_DIR/image/Applications"
# Explicit export list: excludes all upstream firmware/audio binaries, install/probe scripts, and git history.
cp Package.swift LICENSE THIRD_PARTY_NOTICES.md README.md architecture.md SECURITY.md TESTING.md TODO.md CHANGELOG.md "$STAGE_DIR/source/SIM-Station/"
cp -R Station StationResources StationTests script "$STAGE_DIR/source/SIM-Station/"
cp -R Sources/CModemBridge "$STAGE_DIR/source/SIM-Station/Sources/"
DMG='artifacts/SIM-Station-0.1.0-preview-arm64.dmg'
ZIP='artifacts/SIM-Station-0.1.0-preview-source.zip'
if [[ -e "$DMG" || -e "$ZIP" ]]; then
    echo 'Refusing to overwrite an existing delivery. Move or version it explicitly.' >&2
    exit 1
fi
hdiutil create -volname 'SIM Station Preview' -srcfolder "$STAGE_DIR/image" -format UDZO "$DMG"
ditto --norsrc --noextattr --noqtn -c -k --keepParent "$STAGE_DIR/source/SIM-Station" "$ZIP"
(cd artifacts && shasum -a 256 "$(basename "$DMG")" "$(basename "$ZIP")") > artifacts/SHA256SUMS.txt
cat artifacts/SHA256SUMS.txt
echo "Staging retained for inspection: $STAGE_DIR"
