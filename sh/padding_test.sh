#!/usr/bin/env bash
# Exercises padding.sh (aliases ww, wh) against a throwaway copy of the
# repo layout, so the real ghostty includes stay untouched.
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/sh"
cp "$(dirname "${BASH_SOURCE[0]}")/padding.sh" "$tmp/sh/"
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

pad() { bash "$tmp/sh/padding.sh" "$@" >/dev/null 2>&1; }
value() { # file key
    sed -n "s/^$2 = //p" "$tmp/ghostty/$1" 2>/dev/null
}
is() { [ "$(value "$1" "$2")" = "$3" ]; }

check "x from unset lands on the first preset" pad x
check "...written to width-active.conf" \
    is width-active.conf window-padding-x 400
check "x toggles to the second preset" pad x
check "...600" is width-active.conf window-padding-x 600
check "x toggles back" pad x
check "...400" is width-active.conf window-padding-x 400

check "y from unset lands on the first preset" pad y
check "...written to height-active.conf" \
    is height-active.conf window-padding-y 12
check "y toggles to the second preset" pad y
check "...120" is height-active.conf window-padding-y 120
check "y leaves x alone" is width-active.conf window-padding-x 400

check "y takes any number" pad y 75
check "...75" is height-active.conf window-padding-y 75
check "toggling off a custom value lands on the first preset" pad y
check "...12" is height-active.conf window-padding-y 12

check "a non-number is refused" eval '! pad y 7o'
check "...and leaves the file as it was" \
    is height-active.conf window-padding-y 12
check "a missing axis is refused" eval '! pad'
check "an unknown axis is refused" eval '! pad z 10'
check "a y file holds only window-padding-y" \
    eval '! grep -q window-padding-x "$tmp/ghostty/height-active.conf"'

[ "$fails" -eq 0 ]
