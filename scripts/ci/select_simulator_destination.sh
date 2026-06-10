#!/bin/bash
set -euo pipefail

SIMCTL="${SIMCTL:-}"

if [[ -z "$SIMCTL" ]]; then
  if [[ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/simctl" ]]; then
    SIMCTL="/Applications/Xcode.app/Contents/Developer/usr/bin/simctl"
  else
    SIMCTL="xcrun simctl"
  fi
fi

if ! devices="$($SIMCTL list devices 2>&1)"; then
  echo "$devices" >&2
  exit 1
fi

find_udid_for_name() {
  local name="$1"

  printf '%s\n' "$devices" |
    awk -v device_name="$name" '
      index($0, device_name " (") && ($0 ~ /\(Shutdown\)|\(Booted\)/) {
        if (match($0, /\([0-9A-Fa-f-]{36}\)/)) {
          print substr($0, RSTART + 1, RLENGTH - 2)
          exit
        }
      }
    '
}

for preferred_name in \
  "iPhone 17 Pro" \
  "iPhone 16 Pro" \
  "iPhone 15 Pro" \
  "iPhone 14 Pro" \
  "iPhone 13 Pro"; do
  udid="$(find_udid_for_name "$preferred_name")"
  if [[ -n "$udid" ]]; then
    printf 'platform=iOS Simulator,id=%s\n' "$udid"
    exit 0
  fi
done

udid="$(
  printf '%s\n' "$devices" |
    awk '
      /iPhone/ && ($0 ~ /\(Shutdown\)|\(Booted\)/) {
        if (match($0, /\([0-9A-Fa-f-]{36}\)/)) {
          print substr($0, RSTART + 1, RLENGTH - 2)
          exit
        }
      }
    '
)"

if [[ -z "$udid" ]]; then
  echo "No available iPhone simulator was found." >&2
  echo "$devices" >&2
  exit 1
fi

printf 'platform=iOS Simulator,id=%s\n' "$udid"
