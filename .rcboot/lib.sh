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

# ── Modules ───────────────────────────────────────────────────────────────────
# A module is .rcboot/<name>/module.sh, run top to bottom by run_modules. Its
# link, step and hook calls install when $RC_MODE is install, and only verify,
# counting failures in $RC_FAILURES, when it is ensure.
RC_BOOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RC_MODE=install
RC_FAILURES=0
if [ "$(uname)" = Darwin ]; then RC_OS=darwin; else RC_OS=linux; fi

# Repo paths whose link changed in this run, one per line, so a hook can redo
# expensive work (bat's cache) only when its link moved.
RC_LINKS_CHANGED=""

_link_changed() {
    printf '%s\n' "$RC_LINKS_CHANGED" | grep -qxF "$1"
}

# link <repo path> <destination>. A [FAIL] does not stop the run; --ensure is
# the net that catches it afterwards.
link() {
    local src="$DOTFILES_DIR/$1" dst="$2" kind=file
    [ -d "$src" ] && kind=dir
    if [ "$RC_MODE" = ensure ]; then
        _check_link "$1" "$dst" "$src" || RC_FAILURES=$((RC_FAILURES + 1))
        return 0
    fi
    if [ "$(_link_state "$src" "$dst")" != ok ]; then
        RC_LINKS_CHANGED+="$1"$'\n'
    fi
    _relink "$1" "$kind" "$src" "$dst" || true
}

# Fragments a module enables: one link in ~/.config/rc/<tool>/ per file of
# <tool>/rc.d/. The loaders read only that directory, so linking a fragment
# is what turns it on. Literal ~/.config: tmux expands nothing else.
RC_ENABLED="$HOME/.config/rc"
RC_FRAGMENTS=""

# fragment <repo path>, e.g. fragment zsh/rc.d/16-fzf.zsh
fragment() {
    local tool="${1%%/*}" name="${1##*/}"
    RC_FRAGMENTS+="$tool/$name"$'\n'
    link "$1" "$RC_ENABLED/$tool/$name"
}

# Fragment links no module of this run enabled are removed, or reported under
# --ensure; that is what makes a lower level take effect. At level $1 >= 3
# every rc.d/ file should be enabled, so one that is not was never registered.
_sync_fragments() {
    local f rel
    for f in "$RC_ENABLED"/*/*; do
        [ -L "$f" ] || continue
        rel="${f#"$RC_ENABLED"/}"
        printf '%s' "$RC_FRAGMENTS" | grep -qxF "$rel" && continue
        if [ "$RC_MODE" = ensure ]; then
            echo "[FAIL] Enabled by no module: $f"
            RC_FAILURES=$((RC_FAILURES + 1))
        else
            rm "$f" && echo "[OK] Disabled $rel"
        fi
    done
    [ "$1" -ge 3 ] || return 0
    for f in "$DOTFILES_DIR"/*/rc.d/[0-9][0-9]-*; do
        rel="${f#"$DOTFILES_DIR"/}"
        printf '%s' "$RC_FRAGMENTS" | grep -qxF "${rel%%/*}/${f##*/}" \
            && continue
        echo "[FAIL] $rel belongs to no module"
        [ "$RC_MODE" != ensure ] || RC_FAILURES=$((RC_FAILURES + 1))
    done
}

# step <install function> [ensure function]: a failed install stops the run
# (set -e), since later modules build on earlier ones. Either name may be -.
step() {
    if [ "$RC_MODE" = ensure ]; then
        [ -n "${2:-}" ] && [ "$2" != - ] || return 0
        "$2" || RC_FAILURES=$((RC_FAILURES + 1))
    elif [ "$1" != - ]; then
        "$1"
    fi
}

# hook: like step, for upkeep around links (seeding, permissions, caches),
# whose failure is reported but does not stop the run.
hook() {
    if [ "$RC_MODE" = ensure ]; then
        step - "${2:-}"
    elif [ "$1" != - ]; then
        "$1" || true
    fi
}

# Module names up to level $1 from the registry, in file order.
_registry() {
    local level name
    while read -r level name; do
        case "$level" in ''|'#'*) continue ;; esac
        if [ "$level" -le "$1" ]; then
            echo "$name"
        fi
    done < "$RC_BOOT/modules"
}

# The list is on fd 3: on stdin, the first module that reads it (vim
# +PlugInstall) swallows the rest. Not < /dev/null either, so modules keep the
# real stdin for sudo, chsh and passphrase prompts.
run_modules() {
    local name
    while read -r name <&3; do
        echo "[MODULE] $name"
        source "$RC_BOOT/$name/module.sh"
        echo ""
    done 3< <(_registry "$1")
    echo "[MODULE] enabled fragments"
    _sync_fragments "$1"
    echo ""
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
