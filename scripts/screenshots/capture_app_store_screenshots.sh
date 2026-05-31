#!/bin/bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
PROJECT="${PROJECT:-$REPO_ROOT/Diary.xcodeproj}"
SCHEME="${SCHEME:-Diary}"
OUTPUT_DIR="${SCREENSHOT_DIR:-$REPO_ROOT/AppStoreScreenshots/iPhone-6.9}"
RESULT_BUNDLE="${RESULT_BUNDLE:-}"
XCODEBUILD="${XCODEBUILD:-}"
SIMCTL="${SIMCTL:-}"
DESTINATION="${DESTINATION:-}"
DEFAULT_XCODE_DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
TEMP_DIR=""

if [[ -z "${DEVELOPER_DIR:-}" && -d "$DEFAULT_XCODE_DEVELOPER_DIR" ]]; then
  export DEVELOPER_DIR="$DEFAULT_XCODE_DEVELOPER_DIR"
fi

if [[ -z "$XCODEBUILD" ]]; then
  if [[ -n "${DEVELOPER_DIR:-}" && -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
    XCODEBUILD="$DEVELOPER_DIR/usr/bin/xcodebuild"
  else
    XCODEBUILD="xcodebuild"
  fi
fi

if [[ -z "$SIMCTL" ]]; then
  if [[ -n "${DEVELOPER_DIR:-}" && -x "$DEVELOPER_DIR/usr/bin/simctl" ]]; then
    SIMCTL="$DEVELOPER_DIR/usr/bin/simctl"
  else
    SIMCTL="xcrun simctl"
  fi
fi

find_destination() {
  local devices
  devices="$($SIMCTL list devices 2>&1)"

  for name in "iPhone 17 Pro Max" "iPhone 16 Pro Max" "iPhone 15 Pro Max"; do
    local udid
    udid="$(
      printf '%s\n' "$devices" |
        awk -v device_name="$name" '
          index($0, device_name " (") && ($0 ~ /\(Shutdown\)|\(Booted\)/) {
            if (match($0, /\([0-9A-Fa-f-]{36}\)/)) {
              print substr($0, RSTART + 1, RLENGTH - 2)
              exit
            }
          }
        '
    )"

    if [[ -n "$udid" ]]; then
      printf 'platform=iOS Simulator,id=%s\n' "$udid"
      return 0
    fi
  done

  echo "Could not find an available Pro Max iPhone simulator." >&2
  echo "$devices" >&2
  return 1
}

if [[ -z "$DESTINATION" ]]; then
  DESTINATION="$(find_destination)"
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/diary-app-store-screenshots.XXXXXX")"
ATTACHMENTS_DIR="$TEMP_DIR/Attachments"

if [[ -z "$RESULT_BUNDLE" ]]; then
  RESULT_BUNDLE="$TEMP_DIR/ScreenshotCapture.xcresult"
fi

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"
find "$OUTPUT_DIR" -maxdepth 1 -type f \( -name '*.png' -o -name 'manifest.json' \) -delete

echo "Writing App Store screenshots to: $OUTPUT_DIR"
echo "Using destination: $DESTINATION"

"$XCODEBUILD" \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -only-testing:DiaryUITests/AppStoreScreenshotTests/testCaptureAppStoreScreenshots \
  test

DEVELOPER_DIR="${DEVELOPER_DIR:-}" /usr/bin/xcrun xcresulttool export attachments \
  --path "$RESULT_BUNDLE" \
  --output-path "$ATTACHMENTS_DIR"

/usr/bin/ruby -rjson -rfileutils -e '
  manifest_path, attachments_dir, output_dir = ARGV
  expected = %w[
    01-trackers
    02-tracker-detail
    03-new-entry
    04-entry-detail
    05-insights
    06-customize-tracker
  ]
  data = JSON.parse(File.read(manifest_path))
  attachments = data.flat_map { |entry| entry.fetch("attachments", []) }

  expected.each do |name|
    attachment = attachments.find do |candidate|
      candidate.fetch("suggestedHumanReadableName", "").start_with?("#{name}-")
    end
    abort "Missing screenshot attachment for #{name}" unless attachment

    source = File.join(attachments_dir, attachment.fetch("exportedFileName"))
    destination = File.join(output_dir, "#{name}.png")
    FileUtils.cp(source, destination)
  end
' "$ATTACHMENTS_DIR/manifest.json" "$ATTACHMENTS_DIR" "$OUTPUT_DIR"

echo "Captured screenshots:"
find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.png' -print | sort
