#!/bin/bash
set -euo pipefail

PROJECT="${PROJECT:-Diary.xcodeproj}"
SCHEME="${SCHEME:-Diary}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DESTINATION="${DESTINATION:-}"
XCODEBUILD="${XCODEBUILD:-}"

if [[ -z "$XCODEBUILD" ]]; then
  if [[ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]]; then
    XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
  else
    XCODEBUILD="xcodebuild"
  fi
fi

if [[ -z "$DESTINATION" ]]; then
  DESTINATION="$("$SCRIPT_DIR/select_simulator_destination.sh")"
fi

echo "Using test destination: $DESTINATION"

"$XCODEBUILD" \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  test
