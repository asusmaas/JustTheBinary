#!/bin/bash
# Repacks upstream r0ml/JustTheBinary's OpenCV.xcframework.zip into a slim,
# iOS-only xcframework:
#   - keeps the ios-arm64 device slice and the simulator's arm64 slice;
#     drops macOS, Mac Catalyst and x86_64 (Intel simulators are unsupported)
#   - strips debug symbols from the static archives
#   - lays both frameworks out shallow, as iOS requires (upstream's simulator
#     slice is macOS-style and fails with "expected Info.plist at the root level")
#   - writes MinimumOSVersion into each framework's Info.plist, which App Store
#     Connect rejects as missing with error 90530
#
# Usage: slim-opencv.sh <upstream OpenCV.xcframework.zip> <output dir>
# Writes <output dir>/OpenCV.xcframework.zip and prints its SwiftPM checksum.

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <upstream OpenCV.xcframework.zip> <output dir>" >&2
  exit 64
fi
src_zip=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
mkdir -p "$2"
out_dir=$(cd "$2" && pwd)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

unzip -q "$src_zip" \
  'OpenCV.xcframework/ios-arm64/*' \
  'OpenCV.xcframework/ios-arm64_x86_64-simulator/*' \
  -d "$work/src"

# First existing path among the arguments: upstream ships some slices deep
# (Versions/A/...) and some shallow.
first_existing() {
  for p in "$@"; do
    if [ -e "$p" ]; then
      echo "$p"
      return
    fi
  done
  echo "missing: $*" >&2
  exit 1
}

# slim_framework <upstream OpenCV.framework> <destination OpenCV.framework>
slim_framework() {
  local src=$1 dst=$2
  local bin plist privacy
  bin=$(first_existing "$src/Versions/A/OpenCV" "$src/OpenCV")
  plist=$(first_existing "$src/Versions/A/Resources/Info.plist" "$src/Info.plist")
  privacy=$(first_existing "$src/Versions/A/Resources/PrivacyInfo.xcprivacy" "$src/PrivacyInfo.xcprivacy")

  mkdir -p "$dst"
  ditto "$(first_existing "$src/Versions/A/Headers" "$src/Headers")" "$dst/Headers"
  ditto "$(first_existing "$src/Versions/A/Modules" "$src/Modules")" "$dst/Modules"
  cp "$privacy" "$dst/PrivacyInfo.xcprivacy"

  lipo -thin arm64 "$bin" -output "$work/thin.a"
  xcrun strip -S -o "$dst/OpenCV" "$work/thin.a"
  xcrun ranlib -no_warning_for_no_symbols "$dst/OpenCV"
  rm "$work/thin.a"

  # The deployment target the archive was compiled for.
  local minos
  minos=$({ otool -l "$dst/OpenCV" || true; } | awk '$1 == "minos" { print $2; exit }')
  [ -n "$minos" ] || { echo "no minos in $dst/OpenCV" >&2; exit 1; }
  cp "$plist" "$dst/Info.plist"
  /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string $minos" "$dst/Info.plist"
}

slim_framework "$work/src/OpenCV.xcframework/ios-arm64/OpenCV.framework" \
  "$work/device/OpenCV.framework"
slim_framework "$work/src/OpenCV.xcframework/ios-arm64_x86_64-simulator/OpenCV.framework" \
  "$work/simulator/OpenCV.framework"

xcodebuild -create-xcframework \
  -framework "$work/device/OpenCV.framework" \
  -framework "$work/simulator/OpenCV.framework" \
  -output "$work/OpenCV.xcframework" >/dev/null

rm -f "$out_dir/OpenCV.xcframework.zip"
(cd "$work" && ditto -c -k --keepParent OpenCV.xcframework "$out_dir/OpenCV.xcframework.zip")

echo "wrote $out_dir/OpenCV.xcframework.zip"
echo "checksum: $(swift package compute-checksum "$out_dir/OpenCV.xcframework.zip")"
