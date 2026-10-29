#!/usr/bin/env bash
# Packs build/DockMinimize.app into build/DockMinimize.dmg with an Applications shortcut.
# The name has no version, so releases/latest/download/DockMinimize.dmg always gets the newest.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME=DockMinimize
APP="build/$APP_NAME.app"
[[ -d "$APP" ]] || { echo "Run scripts/build-app.sh first" >&2; exit 1; }

stage="build/dmg"
dmg="build/$APP_NAME.dmg"

rm -rf "$stage" "$dmg"
mkdir -p "$stage"
cp -R "$APP" "$stage/"
ln -s /Applications "$stage/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$stage" -format UDZO -quiet "$dmg"
rm -rf "$stage"
echo "Built $dmg"
