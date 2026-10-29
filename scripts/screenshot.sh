#!/usr/bin/env bash
# Renders the settings window into docs/ for the README.
set -euo pipefail
cd "$(dirname "$0")/.."

sources=$(ls Sources/DockMinimize/*.swift | grep -v '/main.swift$')
mkdir -p build docs
# The embedded Info.plist gives the tool the real version number.
swiftc -O -swift-version 5 $sources scripts/screenshot/main.swift -o build/screenshot \
  -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker Resources/Info.plist
build/screenshot docs
