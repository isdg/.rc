#!/usr/bin/env bash
# Claude Code worktree hooks: worktrees live at ~/<prefix>-<name>, named
# from the postfix lists. Usage: worktree.sh create  (hook JSON on stdin)
set -euo pipefail

self="$(readlink -f "${BASH_SOURCE[0]}")"
postfix="${WT_POSTFIX:-$(dirname "$self")/../../postfix}"
marker=claude-worktree

die() { echo "worktree: $*" >&2; exit 1; }

# Literatura alone, then literatura joined with itself and every other list.
names() {
    local lit="$postfix/git/literatura.txt" a b others
    [ -r "$lit" ] || die "no name list at $lit"
    shopt -s nullglob
    others=("$postfix"/*.txt)
    cat "$lit"
    while read -r a; do
        cat "$lit" "${others[@]}" | while read -r b; do
            [ -n "$b" ] && [ "$a" != "$b" ] && echo "$a-$b"
        done
    done < "$lit"
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
    local input cwd common main pre name dir ref
    input="$(cat)"
    cwd="$(jq -r .cwd <<<"$input")"
    common="$(git -C "$cwd" rev-parse --path-format=absolute \
        --git-common-dir 2>/dev/null)" || die "$cwd is not a git repo"
    main="$(dirname "$common")"
    pre="$(prefix "$main")"
    cd "$main"
    ref="$(base_ref)"

    # mkdir is the reservation, so agents spawned together never collide.
    while read -r name; do
        dir="$HOME/$pre-$name"
        git show-ref -q --verify "refs/heads/wt/$name" && continue
        mkdir "$dir" 2>/dev/null || continue
        if ! git worktree add -q -b "wt/$name" "$dir" "$ref" >&2; then
            rmdir "$dir" 2>/dev/null || true
            die "git worktree add failed for $dir"
        fi
        date +%s > "$(git -C "$dir" rev-parse --git-dir)/$marker"
        copy_includes "$main" "$dir"
        echo "$dir"
        return 0
    done < <(names)
    die "every name is taken; extend $postfix"
}

case "${1:-}" in
    create) create ;;
    *) die "usage: worktree.sh create" ;;
esac
