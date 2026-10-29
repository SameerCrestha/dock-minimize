#!/usr/bin/env bash
# Builds build/DockMinimize.app.
#   VERSION=1.2.3          set the app version (default: the one in Resources/Info.plist)
#   ARCHS="arm64 x86_64"   universal build (needs full Xcode; default: this Mac's arch)
#   SIGN_IDENTITY="..."    codesign identity (default: "DockMinimize Dev" if in the keychain, else ad-hoc "-")
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME=DockMinimize
APP="build/$APP_NAME.app"

arch_flags=()
for arch in ${ARCHS:-}; do arch_flags+=(--arch "$arch"); done

swift build -c release ${arch_flags[@]+"${arch_flags[@]}"}
bin_dir=$(swift build -c release ${arch_flags[@]+"${arch_flags[@]}"} --show-bin-path)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$bin_dir/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [[ -n "${VERSION:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
fi

# A stable identity keeps the Accessibility grant across rebuilds; ad-hoc loses it every build.
if [[ -z "${SIGN_IDENTITY:-}" ]] && security find-certificate -c "DockMinimize Dev" >/dev/null 2>&1; then
  SIGN_IDENTITY="DockMinimize Dev"
fi
codesign --force --options runtime --sign "${SIGN_IDENTITY:--}" "$APP"
echo "Built $APP"
