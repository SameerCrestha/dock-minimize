#!/usr/bin/env bash
# Rebuilds and starts the app for local testing.
# With the signing certificate the Accessibility grant is kept. An ad-hoc build has a new signature
# each time, so then this clears the old grant and macOS asks again on launch.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/build-app.sh
pkill -x DockMinimize 2>/dev/null || true
if codesign -dv build/DockMinimize.app 2>&1 | grep -q "Signature=adhoc"; then
  tccutil reset Accessibility io.github.sameercrestha.dockminimize >/dev/null 2>&1 || true
fi
open build/DockMinimize.app
echo "Started. Logs: log stream --level info --predicate 'subsystem == \"io.github.sameercrestha.dockminimize\"'"
