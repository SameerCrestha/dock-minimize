#!/usr/bin/env bash
# Renders the settings window into docs/ for the README.
set -euo pipefail
cd "$(dirname "$0")/.."

sources=$(ls Sources/DockMinimize/*.swift | grep -v '/main.swift$')
mkdir -p build docs
swiftc -O -swift-version 5 $sources scripts/screenshot/main.swift -o build/screenshot
build/screenshot docs
