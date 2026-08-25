#!/bin/bash
# Cycle (or set) Ghostty's horizontal padding — the knob that decides how wide
# the text column is. Alias: `ww`.
#
#   ww        -> next pinned width
#   ww 500    -> that width directly
#
# Same idiom as toggle_theme.sh: the value that changes lives in
# ghostty/width-<N>.conf and is chosen by the gitignored width-active.conf
# symlink, which ghostty/config includes. Nothing rewrites the tracked config, so
# changing width never dirties the repo — the reason a sed on `window-padding-x`
# was not the answer.
#
# Larger padding = narrower text column. Ghostty re-reads its config on
# cmd+shift+, ; nothing here can force a running window to reload.
set -u

WIDTHS=(300 500 600)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GHOSTTY_DIR="$SCRIPT_DIR/ghostty"
LINK="$GHOSTTY_DIR/width-active.conf"

usage() {
    printf 'usage: ww [%s]\n' "$(IFS='|'; echo "${WIDTHS[*]}")" >&2
    exit 2
}

# Current = whatever the symlink points at; unset/broken counts as the first
# width, so a fresh clone (the symlink is gitignored) cycles instead of failing.
cur=""
[ -L "$LINK" ] && cur="$(basename "$(readlink "$LINK")")"
cur="${cur#width-}"
cur="${cur%.conf}"

if [ $# -gt 0 ]; then
    case "$1" in
        -h|--help) usage ;;
    esac
    next=""
    for w in "${WIDTHS[@]}"; do
        [ "$1" = "$w" ] && next="$w"
    done
    if [ -z "$next" ]; then
        printf 'width.sh: %s is not pinned (%s)\n' "$1" "${WIDTHS[*]}" >&2
        exit 1
    fi
else
    # Advance to the next pinned width, wrapping. An unrecognised current value
    # lands on the first one.
    next="${WIDTHS[0]}"
    for i in "${!WIDTHS[@]}"; do
        if [ "${WIDTHS[$i]}" = "$cur" ]; then
            next="${WIDTHS[$(( (i + 1) % ${#WIDTHS[@]} ))]}"
            break
        fi
    done
fi

if [ ! -f "$GHOSTTY_DIR/width-$next.conf" ]; then
    printf 'width.sh: missing %s\n' "$GHOSTTY_DIR/width-$next.conf" >&2
    exit 1
fi

ln -sf "width-$next.conf" "$LINK"
printf 'ghostty padding-x: %s -> %s  (cmd+shift+, to reload)\n' "${cur:-unset}" "$next"
