#!/usr/bin/env bash
# Shared helpers for bootstrap components

# What linking $src to $dst would do to whatever sits at $dst right now. Echoes
# exactly one of:
#
#   ok         already the link we want — nothing to do
#   new        nothing there; the link is a pure addition
#   overwrite  a real file or directory that has to be moved to .backup first
#   relink     a symlink pointing somewhere else, which ln -sf silently repoints
#
# The one place link state is decided: _relink installs from it, _check_link
# verifies from it, and the bootstrap journal turns the overwrite/relink cases
# into the modifications it asks you to describe. A dangling symlink lands in
# `relink` (its realpath is empty, $src's is not), which is what we want — it
# is about to be replaced either way.
_link_state() {
    local src="$1" dst="$2"

    if [ -L "$dst" ]; then
        if [ "$(realpath "$dst" 2>/dev/null)" = "$(realpath "$src" 2>/dev/null)" ]; then
            echo ok
        else
            echo relink
        fi
    elif [ -e "$dst" ]; then
        # Same inode, not a symlink: $dst *is* $src reached by another path —
        # e.g. ~/.vim being the repo's vim/.vim. There is nothing to link and
        # nothing to back up; calling it `overwrite` would move the repo's own
        # file aside.
        if [ "$dst" -ef "$src" ]; then
            echo ok
        else
            echo overwrite
        fi
    else
        echo new
    fi
}

# Verify that $link resolves to $target.
# Prints [OK] or [FAIL] and returns 1 on failure.
_check_link() {
    local label="$1" link="$2" target="$3"
    case "$(_link_state "$target" "$link")" in
        ok)
            echo "[OK] Linked: $label"
            ;;
        relink)
            echo "[FAIL] Wrong link: $label -> $(readlink "$link") (expected -> $target)"
            return 1
            ;;
        *)
            echo "[FAIL] Not linked: $label ($link missing or not a symlink)"
            return 1
            ;;
    esac
}

# Link $src to $dst, backing up whatever real file or directory is in the way.
# $kind is `file` or `dir`: a directory needs ln -sfn, because plain ln -sf
# follows an existing symlink-to-a-directory and drops the new link *inside* the
# old target instead of replacing it.
_relink() {
    local label="$1" kind="$2" src="$3" dst="$4"
    local state
    state="$(_link_state "$src" "$dst")"

    if [ "$state" = ok ]; then
        echo "[SKIP] $label already in place"
        return 0
    fi

    # A missing parent is why this used to print [OK] over a failed ln: the exit
    # status went unchecked, so a run before create_directories claimed success
    # and linked nothing.
    mkdir -p "$(dirname "$dst")"

    if [ "$state" = overwrite ]; then
        echo "[BACKUP] Backing up existing $label to $(basename "$dst").backup"
        mv "$dst" "$dst.backup"
    fi

    local -a flags
    if [ "$kind" = dir ]; then
        flags=(-sfn)
    else
        flags=(-sf)
    fi

    if ln "${flags[@]}" "$src" "$dst"; then
        echo "[OK] Linked $label"
    else
        echo "[FAIL] Could not link $label ($dst -> $src)"
        return 1
    fi
}
