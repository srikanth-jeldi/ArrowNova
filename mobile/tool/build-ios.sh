#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo "iOS archives require macOS and Xcode. Run this script on the release Mac." >&2
  exit 1
fi
if [[ $# -ne 3 || ! "$3" =~ ^[1-9][0-9]*$ || ( "$1" != test && "$1" != store ) ]]; then
  echo "Usage: bash tool/build-ios.sh test|store APPLE_TEAM_ID UNUSED_BUILD_NUMBER" >&2
  exit 1
fi
for command in flutter python3 pod xcodebuild; do
  command -v "$command" >/dev/null || { echo "Missing $command. Complete the Mac setup guide." >&2; exit 1; }
done
sdk_version="$(xcrun --sdk iphoneos --show-sdk-version)"
if (( ${sdk_version%%.*} < 26 )); then
  echo "Use stable Xcode with iOS SDK 26 or newer for App Store uploads." >&2
  exit 1
fi
python3 tool/ios_release.py configure --mode "$1" --team "$2"
flutter pub get
flutter build ios --config-only --release --build-number="$3" \
  --dart-define-from-file=.build-tmp/ios/defines.json
(cd ios && pod install)
flutter build ipa --release --build-number="$3" \
  --dart-define-from-file=.build-tmp/ios/defines.json \
  --export-options-plist=.build-tmp/ios/ExportOptions.plist
python3 tool/ios_release.py verify --mode "$1"
echo "Archive: mobile/build/ios/archive/Runner.xcarchive"
echo "IPA: mobile/build/ios/ipa/"
echo "This script does not upload or publish. Follow the TestFlight handover guide."
