#!/usr/bin/env bash
# Exercises run.sh against a throwaway HOME and log dir, and checks that
# every job plist lints and runs run.sh under its own name.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home" "$tmp/logs"
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

run() {
    HOME="$tmp/home" RC_JOB_LOG_DIR="$tmp/logs" RC_JOB_LOG_MAX=200 \
        bash "$here/run.sh" "$@" > /dev/null 2>&1
}
not() { ! "$@"; }
log() { cat "$tmp/logs/$1.log"; }
has() { log "$1" | grep -q -- "$2"; }
lines() { [ "$(log "$1" | wc -l | tr -d ' ')" = "$2" ]; }

check "a passing job exits 0" run ok sh -c 'echo hello'
check "...its output lands in the log" has ok '^hello$'
check "...between a start line" has ok '^== .* start: sh -c echo hello$'
check "...and an exit line" has ok '^== .* exit 0 after [0-9]*s$'

check "a failing job passes its status on" \
    not run bad sh -c 'echo oops >&2; exit 3'
check "...stderr lands in the log" has bad '^oops$'
check "...the exit line names the status" has bad '^== .* exit 3 after'

check "runs again append" run ok true
check "...to the same log" lines ok 5

check "the job runs from HOME" run cwd pwd
check "...not from /" has cwd "^$tmp/home\$"

check "the job sees Homebrew on PATH" run path sh -c 'echo "$PATH"'
check "...and the system dirs" has path '/opt/homebrew/bin:.*:/usr/bin:'

head -c 300 /dev/zero > "$tmp/logs/big.log"
check "a log past the cap" run big true
check "...is rotated to .1" test -s "$tmp/logs/big.log.1"
check "...and starts fresh" lines big 2

check "no command is a usage error" not run lonely

for plist in "$here"/com.local.*.plist; do
    name="${plist##*/com.local.}"
    name="${name%.plist}"
    check "$name lints" plutil -lint -s "$plist"
    check "...labels itself com.local.$name" test \
        "$(plutil -extract Label raw "$plist")" = "com.local.$name"
    check "...runs run.sh" test \
        "$(plutil -extract ProgramArguments.2 raw "$plist")" \
        = 'exec "$HOME/.rc/darwin/launchd/run.sh" "$@"'
    check "...under its own name" test \
        "$(plutil -extract ProgramArguments.4 raw "$plist")" = "$name"
done

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
