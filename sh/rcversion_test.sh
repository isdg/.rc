#!/usr/bin/env bash
# rcversion.sh against throwaway repos: an up-to-date checkout, one behind
# origin/main, one with no origin, a plain directory, and no VERSION at all.
set -euo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rcversion.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp" GIT_CONFIG_NOSYSTEM=1

fail=0
check() {
    if [[ "$2" == "$3" ]]; then
        echo "ok   $1"
    else
        printf 'FAIL %s\n  want: %q\n  got:  %q\n' "$1" "$3" "$2"
        fail=1
    fi
}

# repo <dir> <version>: a repo whose one commit holds VERSION.
repo() {
    mkdir -p "$1"
    git -C "$1" init -q
    echo "$2" > "$1/VERSION"
    git -C "$1" add VERSION
    git -C "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false \
        -c core.hooksPath=/dev/null commit -qm v
}

repo "$tmp/same" 0.1.0
git -C "$tmp/same" update-ref refs/remotes/origin/main HEAD
check "same as origin/main" "$(bash "$script" "$tmp/same")" "0.1.0"

repo "$tmp/behind" 0.1.1
git -C "$tmp/behind" update-ref refs/remotes/origin/main HEAD
echo 0.1.0 > "$tmp/behind/VERSION"
check "behind origin/main" "$(bash "$script" "$tmp/behind")" \
    "0.1.0 (origin/main 0.1.1)"

repo "$tmp/alone" 0.2.0
check "no origin/main" "$(bash "$script" "$tmp/alone")" "0.2.0"

mkdir "$tmp/plain"
printf '0.3.0' > "$tmp/plain/VERSION"
check "not a repo, no newline" "$(bash "$script" "$tmp/plain")" "0.3.0"

mkdir "$tmp/none"
out="$(bash "$script" "$tmp/none" 2>&1)" && rc=0 || rc=$?
check "no VERSION fails" "$rc $out" "1 rcversion: no VERSION in $tmp/none"

check "repo from ISGRC" "$(ISGRC="$tmp/alone" bash "$script")" "0.2.0"

exit "$fail"
