#!/usr/bin/env bash
# Shared helpers for bootstrap components

# Can the default toolchain actually link? Builds the smallest possible C
# program; the interesting failures here are all at the link step.
_cc_links() {
    local out rc
    command -v cc >/dev/null 2>&1 || return 1
    out="$(mktemp -t ccprobe)" || return 1
    printf 'int main(void){return 0;}\n' | cc -x c - -o "$out" 2>/dev/null
    rc=$?
    rm -f "$out"
    return $rc
}

# Darwin only: confirm cc can link before handing a Rust or Go build to it, and
# pin SDKROOT to an SDK that works if it cannot.
#
# xcrun selects the highest-numbered SDK under the Command Line Tools, not the
# one the MacOSX.sdk symlink points at. A machine carrying an SDK newer than its
# CLT -- here SDK 27.0 beside CLT 26.6 -- therefore builds against tbd files
# whose target its own linker cannot parse:
#
#   tapi error: malformed file .../MacOSX27.0.sdk/usr/lib/libSystem.B.tbd:
#   unknown architecture arm64e.x1-macos
#
# Every build that links libc dies there. That took out plc, omni and orchbus
# at once, and read as a problem with the repos they clone from -- the clone
# and the compile both succeed, only the final link fails. MacOSX.sdk still
# points at the SDK the CLT shipped with, so prefer that.
#
# A probe rather than a version comparison, because the question is only ever
# "can this linker link", and that is cheap to ask directly.
_export_buildable_sdk() {
    if [ "$(uname)" != "Darwin" ]; then
        return 0
    fi
    # An SDKROOT the caller chose on purpose is not ours to second-guess.
    if [ -n "${SDKROOT:-}" ]; then
        return 0
    fi
    if _cc_links; then
        return 0
    fi

    # Read the broken SDK's version before pinning: xcrun answers for whatever
    # SDKROOT says, so asking afterwards names the fix rather than the problem.
    local fallback broken_ver
    broken_ver="$(xcrun --show-sdk-version 2>/dev/null)"
    fallback="$(xcode-select -p 2>/dev/null)/SDKs/MacOSX.sdk"
    if [ ! -d "$fallback" ]; then
        echo "[WARN] cc cannot link and no MacOSX.sdk to fall back to; native builds will fail"
        return 0
    fi

    # Resolve the symlink: the value is going into the environment of every
    # build below, and an unresolved one is harder to read in a log.
    SDKROOT="$(cd "$fallback" && pwd -P)"
    export SDKROOT

    if _cc_links; then
        echo "[INFO] Default SDK (${broken_ver:-unknown}) will not link; pinned SDKROOT=$SDKROOT"
    else
        echo "[WARN] Neither the default SDK nor $SDKROOT will link; native builds will fail"
        echo "[INFO] Try: xcode-select --install, or softwareupdate --list for a Command Line Tools update"
        unset SDKROOT
    fi
    return 0
}

# What linking $src to $dst would do to whatever sits at $dst right now. Echoes
# exactly one of:
#
#   ok         already the link we want — nothing to do
#   new        nothing there; the link is a pure addition
#   overwrite  a real file or directory that has to be moved to .backup first
#   relink     a symlink pointing somewhere else, which ln -sf silently repoints
#
# The one place link state is decided: _relink installs from it and _check_link
# verifies from it. A dangling symlink lands in `relink` (its realpath is empty,
# $src's is not), which is what we want — it is about to be replaced either way.
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
    # status went unchecked, so a run before create_vim_dirs claimed success
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

# ── Link registry ─────────────────────────────────────────────────────────────
# Each <tool>/links.sh registers what it puts in place, so link_dotfiles and
# ensure_dotfiles read one list and cannot drift apart. A tool adds to:
#
#   RC_LINK_SOURCES  a function printing one `label|kind|src|dst` row per
#                    plain a->b link. A function rather than an array because
#                    rows need runtime resolution ($HOME, Darwin vs XDG) and
#                    guards that drop a row whose source this checkout lacks.
#   RC_LINK_HOOKS    "install_func|ensure_func" for what a row cannot express
#                    (seeding the *-active files, permissions, caches). Either
#                    half may be empty. Hooks run after every row is linked.
RC_LINK_SOURCES=()
RC_LINK_HOOKS=()

# Labels whose link changed during this link_dotfiles run, one per line, so a
# hook can redo expensive work (bat's cache) only when its link moved.
RC_LINKS_CHANGED=""

_dotfile_links() {
    local fn
    for fn in "${RC_LINK_SOURCES[@]}"; do
        "$fn"
    done
    return 0
}

_link_changed() {
    printf '%s\n' "$RC_LINKS_CHANGED" | grep -qxF "$1"
}

# The light/dark mode every *-active file is seeded from, created as `light`
# on first use. toggle_theme.sh maintains it afterwards.
_theme_mode() {
    local theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/isg/theme"
    if [ ! -f "$theme_file" ]; then
        mkdir -p "$(dirname "$theme_file")"
        echo light > "$theme_file"
        echo "[OK] Seeded theme mode file ($theme_file = light)" >&2
    fi
    cat "$theme_file"
}

ensure_dotfiles() {
    echo "[STEP] Verifying dotfiles..."
    local failed=0 label _kind src dst hook

    # Process substitution, not a pipe, so $failed survives the loop.
    while IFS='|' read -r label _kind src dst; do
        _check_link "$label" "$dst" "$src" || failed=1
    done < <(_dotfile_links)

    for hook in "${RC_LINK_HOOKS[@]}"; do
        hook="${hook#*|}"
        [ -n "$hook" ] || continue
        "$hook" || failed=1
    done

    return $failed
}

# A [FAIL] from one row or hook does not stop the others; --ensure is the net
# that catches it afterwards.
link_dotfiles() {
    echo "[STEP] Linking dotfiles..."
    local label kind src dst hook

    RC_LINKS_CHANGED=""
    while IFS='|' read -r label kind src dst; do
        if [ "$(_link_state "$src" "$dst")" != ok ]; then
            RC_LINKS_CHANGED+="$label"$'\n'
        fi
        _relink "$label" "$kind" "$src" "$dst" || true
    done < <(_dotfile_links)

    for hook in "${RC_LINK_HOOKS[@]}"; do
        hook="${hook%%|*}"
        [ -n "$hook" ] || continue
        "$hook" || true
    done
}
