#!/usr/bin/env bash
# Exercises worktree.sh against a throwaway origin, clone and $HOME.
set -euo pipefail

hook="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/worktree.sh")"
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

export HOME="$tmp/home" WT_POSTFIX="$tmp/postfix"
export GIT_CONFIG_GLOBAL="$tmp/gitconfig" GIT_CONFIG_NOSYSTEM=1
git config --global user.name test
git config --global user.email test@example.com
git config --global init.defaultBranch main
mkdir -p "$HOME" "$WT_POSTFIX/git"
printf 'oda\nstih\n' > "$WT_POSTFIX/git/literatura.txt"
printf 'vega\nrigel\ndeneb\n' > "$WT_POSTFIX/stars.txt"

git init -q --bare "$tmp/origin.git"
git clone -q "$tmp/origin.git" "$HOME/proj-main" 2>/dev/null
main="$HOME/proj-main"
printf 'secret.env\n' > "$main/.gitignore"
printf 'secret.env\nnotes.txt\n' > "$main/.worktreeinclude"
git -C "$main" add .gitignore .worktreeinclude
git -C "$main" commit -qm init
git -C "$main" push -q origin main
git -C "$main" remote set-head origin main
echo key > "$main/secret.env"
echo draft > "$main/notes.txt"
git -C "$main" commit -q --allow-empty -m unpushed

create() { jq -n --arg cwd "$1" '{cwd: $cwd, name: "x"}' | "$hook" create; }

first="$(create "$main")"
check "first worktree is ~/proj-oda" test "$first" = "$HOME/proj-oda"
check "branch wt/oda is checked out" \
    test "$(git -C "$first" branch --show-current)" = wt/oda
check "it starts from origin, not local HEAD" \
    test "$(git -C "$first" rev-parse HEAD)" = \
        "$(git -C "$main" rev-parse origin/main)"
check "the marker is written" \
    test -f "$(git -C "$first" rev-parse --git-dir)/claude-worktree"
check "gitignored include is copied" test -f "$first/secret.env"
check "untracked non-ignored file is not" test ! -e "$first/notes.txt"

second="$(create "$first")"
check "a worktree's own cwd resolves to the main checkout" \
    test "$second" = "$HOME/proj-stih"

mkdir "$HOME/proj-oda-stih"
git -C "$main" branch wt/oda-vega
check "taken dirs and branches are skipped" \
    test "$(create "$main")" = "$HOME/proj-oda-rigel"

pids=()
for i in 1 2 3; do create "$main" > "$tmp/par$i" & pids+=($!); done
for p in "${pids[@]}"; do wait "$p"; done
check "concurrent creates get distinct worktrees" \
    test "$(sort -u "$tmp"/par* | wc -l)" -eq 3

create "$main" >/dev/null && create "$main" >/dev/null
check "pairs run out into three-word names" \
    test "$(create "$main")" = "$HOME/proj-oda-stih-vega"

echo solo > "$WT_POSTFIX/git/literatura.txt"
rm "$WT_POSTFIX/stars.txt"
create "$main" >/dev/null
check "a list too short to stack fails instead of looping" \
    bash -c "jq -n '{cwd: \"$main\"}' | '$hook' create 2>&1 |
        grep -q 'every name is taken'"
check "outside git it fails" \
    bash -c "! jq -n '{cwd: \"$tmp\"}' | '$hook' create 2>/dev/null"

[ "$fails" -eq 0 ] || { echo "$fails failed"; exit 1; }
