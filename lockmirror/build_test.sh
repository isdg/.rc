#!/usr/bin/env bash
# Builds LockMirror.saver into a throwaway directory and checks it is a
# signed, loadable bundle whose principal class the binary exports.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fails=0

check() {
    local what="$1"; shift
    if "$@"; then
        echo "ok   $what"
    else
        echo "FAIL $what"
        fails=$((fails + 1))
    fi
}

if [ "$(uname)" != Darwin ]; then
    echo "skip: LockMirror is Darwin-only"
    exit 0
fi

bundle="$tmp/LockMirror.saver"
bin="$bundle/Contents/MacOS/LockMirror"
principal="$(plutil -extract NSPrincipalClass raw "$here/Info.plist")"

check "builds" "$here/build.sh" "$tmp"
check "is a Mach-O bundle for this machine" \
    grep -q "Mach-O 64-bit bundle $(uname -m)" <(file "$bin")
check "has a valid signature" codesign -v "$bundle"
check "defines the principal class" \
    grep -qx "_OBJC_CLASS_\$_$principal" <(nm -jU "$bin")
check "is a library, not a script" \
    test -z "$(nm -gjU "$bin" | grep -x _main)"
check "names its executable" test "$(plutil -extract CFBundleExecutable \
    raw "$bundle/Contents/Info.plist")" = LockMirror
check "rebuilding replaces the bundle" "$here/build.sh" "$tmp"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
