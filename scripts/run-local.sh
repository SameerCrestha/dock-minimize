#!/usr/bin/env bash
# Rebuilds and starts the app for local testing.
# An ad-hoc build has a new signature each time, so the old Accessibility grant stops working.
# Then this clears it, and macOS asks again on launch. With the "DockMinimize Dev" cert the grant is kept.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/build-app.sh
pkill -x DockMinimize 2>/dev/null || true
if codesign -dv build/DockMinimize.app 2>&1 | grep -q "Signature=adhoc"; then
  tccutil reset Accessibility io.github.sameercrestha.dockminimize >/dev/null 2>&1 || true
fi
open build/DockMinimize.app
echo "Started. Logs: log stream --level info --predicate 'subsystem == \"io.github.sameercrestha.dockminimize\"'"
