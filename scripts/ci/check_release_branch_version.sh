#!/bin/bash
set -euo pipefail

PROJECT="${PROJECT:-Diary.xcodeproj}"
TARGET="${TARGET:-Diary}"
CONFIGURATIONS="${CONFIGURATIONS:-Debug Release}"
XCODEBUILD="${XCODEBUILD:-}"

if [[ -z "$XCODEBUILD" ]]; then
  if [[ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]]; then
    XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
  else
    XCODEBUILD="xcodebuild"
  fi
fi

branch="${1:-${GITHUB_REF_NAME:-${CI_BRANCH:-}}}"

if [[ -z "$branch" && "${CI_COMMIT:-}" == refs/heads/* ]]; then
  branch="${CI_COMMIT#refs/heads/}"
fi

if [[ -z "$branch" ]]; then
  branch="$(git branch --show-current 2>/dev/null || true)"
fi

if [[ "$branch" == refs/heads/* ]]; then
  branch="${branch#refs/heads/}"
fi

if [[ ! "$branch" =~ ^r([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "::error::Release branches must be named rX.Y.Z; got '${branch:-unknown}'."
  exit 1
fi

expected_version="${branch#r}"

for configuration in $CONFIGURATIONS; do
  settings="$(
    "$XCODEBUILD" \
      -project "$PROJECT" \
      -target "$TARGET" \
      -configuration "$configuration" \
      -showBuildSettings
  )"

  marketing_version="$(
    printf '%s\n' "$settings" |
      awk -F'= ' '/MARKETING_VERSION/ { gsub(/[[:space:]]/, "", $2); print $2; exit }'
  )"

  if [[ -z "$marketing_version" ]]; then
    echo "::error::Could not read MARKETING_VERSION for target '$TARGET' configuration '$configuration'."
    exit 1
  fi

  if [[ "$marketing_version" != "$expected_version" ]]; then
    echo "::error::Branch '$branch' requires MARKETING_VERSION '$expected_version', but '$TARGET' '$configuration' is '$marketing_version'."
    exit 1
  fi

  echo "$TARGET $configuration MARKETING_VERSION matches $expected_version."
done

echo "Release branch '$branch' matches app version '$expected_version'."
