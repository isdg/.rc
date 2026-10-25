#!/usr/bin/env bash
# Claude Code worktree hooks: worktrees live at ~/<prefix>-<name>, named
# from the postfix lists. Usage: worktree.sh create|remove|guard|gc
# [--dry-run]; hook JSON arrives on stdin.
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

# Removing loses nothing committed: every commit is on a remote, or the
# branch's content already landed upstream (squash and rebase merges too).
upstreamed() {
    local up
    [ -z "$(git -C "$1" rev-list -n1 HEAD --not --remotes)" ] && return 0
    up="$(git -C "$1" symbolic-ref -q --short refs/remotes/origin/HEAD)" ||
        return 1
    [ "$(git -C "$1" merge-tree --write-tree "$up" HEAD 2>/dev/null)" = \
        "$(git -C "$1" rev-parse "$up^{tree}")" ]
}

ours() {
    [ -f "$(git -C "$1" rev-parse --git-dir 2>/dev/null)/$marker" ]
}

drop() {
    local dir="$1" main branch
    main="$(dirname "$(git -C "$dir" rev-parse --path-format=absolute \
        --git-common-dir)")"
    branch="$(git -C "$dir" branch --show-current)"
    git -C "$main" worktree remove --force "$dir" || return 1
    [ -z "$branch" ] || git -C "$main" branch -q -D "$branch"
}

# Claude Code has already asked about uncommitted files; commits it can't see.
remove() {
    local dir
    dir="$(jq -r .worktree_path)"
    ours "$dir" || die "$dir was not made by this hook; leaving it"
    upstreamed "$dir" ||
        die "keeping $dir: it has commits that are not upstream"
    drop "$dir"
}

# wt/<name> is a placeholder: refuse to publish it under that name.
guard() {
    local input cmd seg d to
    set -f
    input="$(cat)"
    cmd="$(jq -r '.tool_input.command // ""' <<<"$input")"
    d="$(jq -r .cwd <<<"$input")"
    while read -r seg; do
        check_push "$d" $seg
        [[ "$seg" =~ ^cd[[:space:]]+([^[:space:]]+)$ ]] || continue
        to="${BASH_REMATCH[1]//[\"\']/}"
        to="$(cd "$d" && cd "${to/#\~/$HOME}" && pwd)" && d="$to" || true
    done < <(awk '{ gsub(/&&|\|\||;|\|/, "\n"); print }' <<<"$cmd")
}

# check_push <dir> <words of one command>: exits 2 to block the call.
check_push() {
    local d="$1" head='' dest=() w
    shift
    set -- "${@//[\"\']/}"
    while [[ "${1:-}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do shift; done
    case "${1:-}" in
        git)
            shift
            while [ $# -gt 0 ]; do
                case "$1" in
                    -C) d="${2/#\~/$HOME}"; shift 2 ;;
                    -c) shift 2 ;;
                    -*) shift ;;
                    *) break ;;
                esac
            done
            [ "${1:-}" = push ] || return 0
            shift
            for w in "$@"; do [[ "$w" == -* ]] || dest+=("${w##*:}"); done
            dest=("${dest[@]:1}") ;;
        gh)
            [ "${2:-}" = pr ] && [ "${3:-}" = create ] || return 0
            shift 3
            while [ $# -gt 0 ]; do
                case "$1" in
                    -H|--head) dest=("$2"); shift 2 ;;
                    --head=*) dest=("${1#--head=}"); shift ;;
                    *) shift ;;
                esac
            done ;;
        *) return 0 ;;
    esac
    head="$(git -C "$d" branch --show-current 2>/dev/null)" || true
    [ ${#dest[@]} -gt 0 ] || dest=(HEAD)
    for w in "${dest[@]}"; do
        [ "$w" = HEAD ] && w="$head"
        if [[ "$w" == wt/* ]]; then
            echo "worktree: $w is a placeholder; rename it first:" \
                "git branch -m <type>/<scope>/<slug>" >&2
            exit 2
        fi
    done
}

# Clean, upstreamed, unlocked, not any live session's directory and older
# than WT_GC_MIN_AGE seconds (1 day): what subagents and workflows leave.
gc() {
    local dry="${1:-}" now dir='' locked line live
    git rev-parse -q --git-dir >/dev/null 2>&1 || return 0
    live="$(claude agents --json | jq -r '.[].cwd')" ||
        die "can't list live sessions, so sweeping nothing"
    [ "$dry" = --dry-run ] || git worktree prune
    now="$(date +%s)"
    while read -r line; do
        case "$line" in
            "worktree "*) dir="${line#worktree }" locked='' ;;
            locked*) locked=1 ;;
            '') [ -z "$dir" ] || sweep "$dir" "$locked"; dir='' ;;
        esac
    done < <(git worktree list --porcelain; echo)
}

sweep() {
    local dir="$1" born
    [ -z "$2" ] && ours "$dir" || return 0
    in_use "$dir" && return 0
    born="$(cat "$(git -C "$dir" rev-parse --git-dir)/$marker")"
    [ $((now - born)) -ge "${WT_GC_MIN_AGE:-86400}" ] || return 0
    [ -z "$(git -C "$dir" status --porcelain)" ] || return 0
    upstreamed "$dir" || return 0
    if [ "$dry" = --dry-run ]; then
        echo "would remove $dir"
    else
        drop "$dir" && echo "removed $dir"
    fi
}

in_use() {
    local c
    while read -r c; do
        [ -n "$c" ] && [[ "$c/" == "$1/"* ]] && return 0
    done <<<"$live"
    return 1
}

case "${1:-}" in
    create) create ;;
    remove) remove ;;
    guard) guard ;;
    gc) gc "${2:-}" ;;
    *) die "usage: worktree.sh create|remove|guard|gc [--dry-run]" ;;
esac
