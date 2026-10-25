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
mkdir -p "$HOME" "$WT_POSTFIX/git" "$tmp/bin"
printf '#!/bin/sh\n[ -z "$FAKE_FAIL" ] || exit 1\ncat %s || echo "[]"\n' \
    "'$tmp/live.json' 2>/dev/null" > "$tmp/bin/claude"
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"
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

printf 'r1\nr2\nr3\nr4\nr5\nr6\nr7\n' > "$WT_POSTFIX/git/literatura.txt"
remove() { jq -n --arg p "$1" '{worktree_path: $p}' | "$hook" remove; }
commit() {
    echo "$2" > "$1/$2"
    git -C "$1" add "$2"
    git -C "$1" commit -qm "$2"
}

w="$(create "$main")"
remove "$w"
check "remove drops a worktree with nothing in it" test ! -e "$w"
check "and deletes its branch" \
    bash -c "! git -C '$main' show-ref -q --verify refs/heads/wt/r1"
check "a freed name is reused" test "$(create "$main")" = "$w"

commit "$w" local
check "remove keeps a worktree with unpushed commits" \
    bash -c "! jq -n '{worktree_path: \"$w\"}' | '$hook' remove 2>/dev/null"
check "so the directory is still there" test -d "$w"
git -C "$w" push -q origin HEAD 2>/dev/null
remove "$w"
check "once pushed, remove drops it" test ! -e "$w"

w="$(create "$main")"
commit "$w" feature
git -C "$main" checkout -q -B land origin/main
git -C "$main" merge -q --squash "$(git -C "$w" branch --show-current)" \
    >/dev/null
git -C "$main" commit -qm squash
git -C "$main" push -q origin land:main
git -C "$main" fetch -q origin
remove "$w"
check "a squash-merged branch counts as upstream" test ! -e "$w"
check "remove refuses a worktree it did not make" \
    bash -c "! jq -n '{worktree_path: \"$main\"}' | '$hook' remove 2>/dev/null"

idle="$(create "$main")"
dirty="$(create "$main")"; echo wip > "$dirty/wip"
locked="$(create "$main")"; git -C "$main" worktree lock "$locked"
ahead="$(create "$main")"; commit "$ahead" ahead
busy="$(create "$main")"; mkdir "$busy/sub"
jq -n --arg c "$(cd "$busy" && pwd -P)/sub" '[{cwd: $c}]' > "$tmp/live.json"
(cd "$main" && "$hook" gc)
check "gc leaves worktrees younger than a day" test -d "$idle"
report="$(cd "$main" && WT_GC_MIN_AGE=0 "$hook" gc --dry-run)"
listed() {
    grep -cxF "would remove $(cd "$1" && pwd -P)" <<<"$report" || true
}
check "gc --dry-run reports the idle worktree once" \
    test "$(listed "$idle")" -eq 1
check "and not the dirty, locked, unpushed or live ones" \
    test "$(listed "$dirty")$(listed "$locked")$(listed "$ahead")$(
        listed "$busy")" = 0000
check "--dry-run removes nothing" test -d "$idle"
gone="$(create "$main")"
rm -rf "$gone"
(cd "$main" && WT_GC_MIN_AGE=0 "$hook" gc --dry-run >/dev/null)
check "--dry-run leaves stale entries for prune" \
    bash -c "git -C '$main' worktree list | grep -q prunable"
check "gc sweeps nothing when it can't list live sessions" \
    bash -c "cd '$main' && ! FAKE_FAIL=1 WT_GC_MIN_AGE=0 '$hook' gc \
        2>/dev/null && test -d '$idle'"
(cd "$dirty" && WT_GC_MIN_AGE=0 "$hook" gc >/dev/null)
check "gc removes an idle worktree, from any checkout" test ! -e "$idle"
check "and prunes stale entries" \
    bash -c "! git -C '$main' worktree list | grep -q prunable"
check "but keeps dirty, locked, unpushed and live ones" \
    test -d "$dirty" -a -d "$locked" -a -d "$ahead" -a -d "$busy"
check "gc outside git is a no-op" bash -c "cd '$tmp' && '$hook' gc"

guard() {
    jq -n --arg cwd "$1" --arg c "$2" \
        '{cwd: $cwd, tool_input: {command: $c}}' |
        "$hook" guard 2>/dev/null && echo 0 || echo $?
}
blocks() { check "guard blocks: $2" test "$(guard "$1" "$2")" = 2; }
allows() { check "guard allows: $2" test "$(guard "$1" "$2")" = 0; }
blocks "$dirty" "git push"
blocks "$dirty" "git push -u origin HEAD"
blocks "$dirty" "gh pr create --fill"
blocks "$main" "git -C $dirty push"
blocks "$main" "cd '$dirty' && git push"
blocks "$main" "FOO=1 git -c a=b push origin \"wt/r9\""
allows "$main" "git push"
allows "$main" "git push origin wt/r9:feat/a/b"
allows "$dirty" "git status && git log --grep push"
allows "$dirty" "gh pr create --head feat/a/b"
git -C "$dirty" branch -m feat/a/b
allows "$dirty" "git push -u origin HEAD"

[ "$fails" -eq 0 ] || { echo "$fails failed"; exit 1; }
