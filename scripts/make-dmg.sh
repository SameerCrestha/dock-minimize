#!/usr/bin/env bash
# Packs build/DockMinimize.app into build/DockMinimize-<version>.dmg with an Applications shortcut.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME=DockMinimize
APP="build/$APP_NAME.app"
[[ -d "$APP" ]] || { echo "Run scripts/build-app.sh first" >&2; exit 1; }

version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
stage="build/dmg"
dmg="build/$APP_NAME-$version.dmg"

rm -rf "$stage" "$dmg"
mkdir -p "$stage"
cp -R "$APP" "$stage/"
ln -s /Applications "$stage/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$stage" -format UDZO -quiet "$dmg"
rm -rf "$stage"
echo "Built $dmg"
