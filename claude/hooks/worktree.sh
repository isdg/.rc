#!/usr/bin/env bash
# Claude Code worktree hooks: worktrees live at ~/<prefix>-<name>, named
# from the postfix lists. Usage: worktree.sh create  (hook JSON on stdin)
set -euo pipefail

self="$(readlink -f "${BASH_SOURCE[0]}")"
postfix="${WT_POSTFIX:-$(dirname "$self")/../../postfix}"
marker=claude-worktree

die() { echo "worktree: $*" >&2; exit 1; }

load_words() {
    local w
    lits=() words=()
    [ -r "$lit" ] || die "no name list at $lit"
    while read -r w; do
        [ -n "$w" ] && lits+=("$w")
    done < "$lit"
    while read -r w; do
        words+=("$w")
    done < <(cat "$lit" "$postfix"/*.txt 2>/dev/null |
        awk 'NF && !seen[$0]++')
}

# Depth-first, so the search stops at the first free name: literatura
# first, then each name stacked with one more word from any list.
claim() {
    local w
    if [ "$2" -eq 0 ]; then
        reserve "$1"
        return
    fi
    for w in "${words[@]}"; do
        [[ "-$1-" == *"-$w-"* ]] && continue
        claim "$1-$w" $(($2 - 1)) && return 0
    done
    return 1
}

# mkdir is the reservation, so agents spawned together never collide.
reserve() {
    dir="$HOME/$pre-$1"
    [[ "$branches" == *$'\n'"wt/$1"$'\n'* ]] && return 1
    [ -e "$dir" ] && return 1
    mkdir "$dir" 2>/dev/null || return 1
    name="$1"
}

# ~/cosmos-main -> cosmos, ~/.rc -> .rc
prefix() {
    local base
    base="$(basename "$1")"
    echo "${base%-main}"
}

# Mirrors worktree.baseRef "fresh": origin's default branch, else HEAD.
base_ref() {
    local ref
    if ref="$(git symbolic-ref -q --short refs/remotes/origin/HEAD)"; then
        git fetch -q origin "${ref#origin/}" >&2 || true
        echo "$ref"
    else
        echo HEAD
    fi
}

# Claude Code's default skips .worktreeinclude once a hook replaces it.
copy_includes() {
    local main="$1" dir="$2" f
    [ -f "$main/.worktreeinclude" ] || return 0
    comm -12 \
        <(git -C "$main" ls-files -oi \
            --exclude-from=.worktreeinclude | sort) \
        <(git -C "$main" ls-files -oi --exclude-standard | sort) |
    while read -r f; do
        mkdir -p "$dir/$(dirname "$f")"
        cp -p "$main/$f" "$dir/$f"
    done
}

create() {
    local input cwd common main pre name dir ref branches depth first
    local lit="$postfix/git/literatura.txt" lits words
    input="$(cat)"
    cwd="$(jq -r .cwd <<<"$input")"
    common="$(git -C "$cwd" rev-parse --path-format=absolute \
        --git-common-dir 2>/dev/null)" || die "$cwd is not a git repo"
    main="$(dirname "$common")"
    pre="$(prefix "$main")"
    cd "$main"
    ref="$(base_ref)"

    branches=$'\n'"$(git for-each-ref --format='%(refname:short)' \
        refs/heads/wt)"$'\n'
    load_words
    name=''
    # No repeated word, so no name is deeper than the word count.
    for ((depth = 0; depth < ${#words[@]}; depth++)); do
        for first in "${lits[@]}"; do
            claim "$first" "$depth" && break 2
        done
    done
    [ -n "$name" ] || die "every name is taken; extend $postfix"

    if ! git worktree add -q -b "wt/$name" "$dir" "$ref" >&2; then
        rmdir "$dir" 2>/dev/null || true
        die "git worktree add failed for $dir"
    fi
    date +%s > "$(git -C "$dir" rev-parse --git-dir)/$marker"
    copy_includes "$main" "$dir"
    echo "$dir"
}

case "${1:-}" in
    create) create ;;
    *) die "usage: worktree.sh create" ;;
esac
