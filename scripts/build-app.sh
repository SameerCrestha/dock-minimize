#!/usr/bin/env bash
# Builds build/DockMinimize.app.
#   VERSION=1.2.3          set the app version (default: the one in Resources/Info.plist)
#   ARCHS="arm64 x86_64"   universal build (needs full Xcode; default: this Mac's arch)
#   SIGNING_P12=path       .p12 with the "DockMinimize Signing" identity (default: ~/.config/dock-minimize/signing.p12)
#   SIGNING_P12_PASSWORD   its password (default: ~/.config/dock-minimize/signing.pass)
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

# The same certificate on every build keeps the Accessibility grant across rebuilds and updates.
# Without it the build is ad-hoc signed, and macOS forgets the grant every time.
config="$HOME/.config/dock-minimize"
p12="${SIGNING_P12:-$config/signing.p12}"
if [[ -f "$p12" ]]; then
  password="${SIGNING_P12_PASSWORD:-$(cat "$config/signing.pass")}"
  # A throwaway keychain, so the login keychain is never touched.
  keychain="$(mktemp -d)/signing.keychain-db"
  keychain_password=$(uuidgen)
  security create-keychain -p "$keychain_password" "$keychain"
  trap 'security delete-keychain "$keychain" 2>/dev/null || true' EXIT
  security unlock-keychain -p "$keychain_password" "$keychain"
  security import "$p12" -k "$keychain" -P "$password" -T /usr/bin/codesign >/dev/null
  security set-key-partition-list -S apple-tool:,apple: -s -k "$keychain_password" "$keychain" >/dev/null
  codesign --force --options runtime --keychain "$keychain" --sign "DockMinimize Signing" "$APP"
else
  echo "No signing certificate, signing ad-hoc" >&2
  codesign --force --options runtime --sign - "$APP"
fi
echo "Built $APP"
