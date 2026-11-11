#!/usr/bin/env bash
# Runs the launchd module against a throwaway HOME and a copy of the job
# plists, with launchctl and agents.sh stubbed to record what they are asked.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(dirname "$(dirname "$here")")"
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

mkdir -p "$tmp/dots/darwin/launchd" "$tmp/bin"
cp "$repo"/darwin/launchd/com.local.*.plist "$tmp/dots/darwin/launchd/"
cat > "$tmp/dots/darwin/launchd/agents.sh" <<EOF
#!/bin/sh
echo "\$*" >> "$tmp/loads"
EOF
cat > "$tmp/bin/launchctl" <<EOF
#!/bin/sh
[ "\$1" = print ] && grep -qxF "\${2##*/}" "$tmp/loaded"
EOF
chmod +x "$tmp/dots/darwin/launchd/agents.sh" "$tmp/bin/launchctl"
PATH="$tmp/bin:$PATH"

# run install|ensure [loaded label...]: one boot.sh pass over the module,
# with the given labels already loaded; its output lands in $tmp/out.
run() {
    local mode="$1"; shift
    printf '%s\n' "$@" > "$tmp/loaded"
    : > "$tmp/loads"
    (
        HOME="$tmp/home" DOTFILES_DIR="$tmp/dots"
        source "$repo/.rcboot/lib.sh"
        RC_OS=darwin RC_MODE="$mode"
        source "$here/module.sh"
        echo "failures=$RC_FAILURES"
    ) > "$tmp/out" 2>&1
}
loads() { [ "$(sort "$tmp/loads" | tr '\n' ' ')" = "$1" ]; }
said() { grep -q -- "$1" "$tmp/out"; }
agent() { echo "$tmp/home/Library/LaunchAgents/com.local.$1.plist"; }
linked() {
    [ "$(readlink "$(agent "$1")")" = \
        "$tmp/dots/darwin/launchd/com.local.$1.plist" ]
}

run install
check "a fresh install links hr-sync" linked hr-sync
check "...and rcstate-sync" linked rcstate-sync
check "...and loads both" loads "load hr-sync load rcstate-sync "

run install com.local.hr-sync com.local.rcstate-sync
check "a second install loads nothing" loads ""

rm "$(agent rcstate-sync)"
run install com.local.hr-sync com.local.rcstate-sync
check "a relinked job is loaded again" loads "load rcstate-sync "

run install com.local.hr-sync
check "an unloaded job is loaded again" loads "load rcstate-sync "

run ensure com.local.hr-sync com.local.rcstate-sync
check "ensure passes with both loaded" said '^failures=0$'
check "...and loads nothing" loads ""

run ensure com.local.hr-sync
check "ensure fails with one not loaded" said '^failures=1$'
check "...and names it" said '^\[FAIL\] com.local.rcstate-sync not loaded'

rm "$(agent hr-sync)"
run ensure com.local.hr-sync com.local.rcstate-sync
check "ensure fails on a missing link" said '^failures=1$'

rm -rf "$tmp/home"
(
    HOME="$tmp/home" DOTFILES_DIR="$tmp/dots"
    source "$repo/.rcboot/lib.sh"
    RC_OS=linux
    source "$here/module.sh"
) > /dev/null 2>&1
check "Linux links nothing" test ! -e "$tmp/home/Library"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
