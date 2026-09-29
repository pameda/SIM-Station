#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
MODE="${1:---verify}"
CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
APP_BUNDLE="$ROOT_DIR/dist/SIM Station.app"
case "$MODE" in
  --test) swift test; exit ;;
  --build|--verify|run|--logs|--debug) ;;
  *) echo "Usage: $0 [--test|--build|--verify|run|--logs|--debug]" >&2; exit 2 ;;
esac
if [[ "$MODE" != "--build" ]]; then pkill -x SIMStation >/dev/null 2>&1 || true; fi
swift build -c "$CONFIGURATION" --product SIMStation -Xswiftc -gnone -Xcc -g0
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
swift script/render_icon.swift "$ROOT_DIR/.build/Station.iconset"
iconutil -c icns "$ROOT_DIR/.build/Station.iconset" -o "$APP_BUNDLE/Contents/Resources/SIMStation.icns"
cp "$BIN_DIR/SIMStation" "$APP_BUNDLE/Contents/MacOS/SIMStation"
cp StationResources/Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp LICENSE "$APP_BUNDLE/Contents/Resources/MaVo-MIT-LICENSE.txt"
cp THIRD_PARTY_NOTICES.md "$APP_BUNDLE/Contents/Resources/UPSTREAM-NOTICES.txt"
codesign --force --sign - "$APP_BUNDLE"
codesign --verify --strict "$APP_BUNDLE"
plutil -lint "$APP_BUNDLE/Contents/Info.plist"
case "$MODE" in
  --build) ;;
  --debug) lldb -- "$APP_BUNDLE/Contents/MacOS/SIMStation" ;;
  *) open -n "$APP_BUNDLE"
     if [[ "$MODE" == "--verify" ]]; then sleep 2; pgrep -x SIMStation >/dev/null; fi
     if [[ "$MODE" == "--logs" ]]; then /usr/bin/log stream --info --predicate 'process == "SIMStation"'; fi ;;
esac
