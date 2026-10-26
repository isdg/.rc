#!/usr/bin/env bash
# Exercises commit-title.sh as a config-based commit-msg hook in a
# throwaway repository and global config.
set -euo pipefail

hook="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/commit-title.sh")"
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

export HOME="$tmp/home" GIT_CONFIG_GLOBAL="$tmp/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
git config --global user.name test
git config --global user.email test@example.com
git config --global hook.commit-title.event commit-msg
git config --global hook.commit-title.command "$hook"
git init -q "$tmp/repo"
cd "$tmp/repo"

commits() { git commit -q --allow-empty "$@" 2>/dev/null; }
refused() { ! commits "$@"; }
fifty="feat(scope): $(printf 'x%.0s' $(seq 1 37))"

check "a 50-character subject passes" commits -m "$fifty"
check "a 51-character subject fails" refused -m "${fifty}y"
check "the body may be longer" \
    commits -m "short" -m "$(printf 'b%.0s' $(seq 1 90))"
check "multibyte characters count once" \
    commits -m "feat: $(printf 'é%.0s' $(seq 1 44))"
check "comment lines before the subject are ignored" \
    commits --cleanup=strip -F <(printf '# note\n\nshort subject\n')
check "a merge subject passes" \
    commits -m "Merge branch 'a-very-long-branch-name' of github.com:x/y"
check "a fixup subject passes" \
    commits -m "fixup! $(printf 'x%.0s' $(seq 1 60))"
check "--no-verify skips the check" \
    commits --no-verify -m "$(printf 'x%.0s' $(seq 1 60))"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
