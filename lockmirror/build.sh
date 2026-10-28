#!/usr/bin/env bash
# Builds LockMirror.saver into a directory (default ~/Library/Screen Savers),
# ad-hoc signed for this machine's architecture.
#
#   build.sh [dir]
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${1:-$HOME/Library/Screen Savers}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

bundle="$tmp/LockMirror.saver"
mkdir -p "$bundle/Contents/MacOS"
cp "$src/Info.plist" "$bundle/Contents/"
swiftc -O -parse-as-library -module-name LockMirror \
    -target "$(uname -m)-apple-macos14" \
    -Xlinker -bundle -framework ScreenSaver \
    -o "$bundle/Contents/MacOS/LockMirror" "$src/LockMirrorView.swift"
codesign -f -s - "$bundle" 2> /dev/null

mkdir -p "$dest"
rm -rf "$dest/LockMirror.saver"
mv "$bundle" "$dest/"
