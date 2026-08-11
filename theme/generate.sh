#!/usr/bin/env bash
# Render every per-tool theme file from theme/palette.sh + theme/templates/.
#
#   bash theme/generate.sh          rewrite the generated files
#   bash theme/generate.sh --check  fail if they are out of date (writes nothing)
#
# The output files are COMMITTED: everything here is symlinked straight into ~/
# (~/.config/ghostty -> ghostty/, ~/.tmux.conf -> tmux/.tmux.conf, …), so there
# is no render step at load time. That is also the review you want — after
# changing a colour, `git diff` shows exactly which tools moved.
#
# Never call this from a shell startup file: zsh startup here is measured and
# defended. It belongs in bootstrap and in your hands.
#
# Templates are separate files rather than heredocs on purpose — adding a colour
# should never mean editing generator logic. This file is meant to stop changing.
# bash-3.2 clean, see palette.sh.

set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)

. "$ROOT/theme/palette.sh"

# What gets rendered: <template> <output path>. MODE is substituted in both, so
# a tool whose two modes differ structurally can carry one template per mode
# (bat does: the light theme has scopes the dark one leaves to inherit).
# Add a tool by writing a template and adding one line here.
ISG_TARGETS='
ghostty.tpl  ghostty/theme-MODE.conf
tmux.tpl     tmux/theme-MODE.conf
tig.tpl      tig/theme-MODE.tigrc
fzf.tpl      fzf/opts-MODE.conf
k9s.tpl      k9s/skins/vs_MODE.yaml
bat-MODE.tpl bat/themes/vs_MODE.tmTheme
nvim-MODE.tpl nvim/colors/vs_MODE.vim
delta.tpl    git/delta-MODE.gitconfig
'

# Placeholder pattern, hoisted into a variable: bash 3.2 mishandles an inline
# `\{` inside [[ =~ ]].
_ph_re='\$\{([A-Za-z_][A-Za-z0-9_]*)\}'

# render <template>  -> stdout
# Substitutes ${ISG_*} and nothing else. Deliberately does not eval: these are
# config files, not code, so a backtick or a $(…) in a template stays literal.
# An unset or empty placeholder is a hard error — a typo'd colour name should
# stop the build, not quietly emit a config with a hole in it.
render() {
    local line name val needle
    while IFS= read -r line || [ -n "$line" ]; do
        while [[ $line =~ $_ph_re ]]; do
            name=${BASH_REMATCH[1]}
            if ! declare -p "$name" >/dev/null 2>&1; then
                printf 'theme: %s: unset placeholder ${%s}\n' "$1" "$name" >&2
                return 1
            fi
            val=${!name}
            if [ -z "$val" ]; then
                printf 'theme: %s: empty placeholder ${%s}\n' "$1" "$name" >&2
                return 1
            fi
            needle='${'$name'}'
            line=${line//"$needle"/$val}
        done
        printf '%s\n' "$line"
    done < "$1"
}

check_only=0
if [ "${1:-}" = '--check' ]; then
    check_only=1
elif [ $# -gt 0 ]; then
    printf 'usage: generate.sh [--check]\n' >&2
    exit 2
fi

stale=0
for mode in dark light; do
    isg_palette "$mode"
    while read -r tpl out; do
        [ -n "$tpl" ] || continue
        tpl=${tpl//MODE/$mode}
        out=${out//MODE/$mode}
        tmp="$ROOT/$out.generating.$$"
        # Render to a temp file first: a failed substitution must not leave a
        # half-written config behind for a tool to load.
        if ! render "$ROOT/theme/templates/$tpl" > "$tmp"; then
            rm -f "$tmp"
            exit 1
        fi
        if [ "$check_only" = 1 ]; then
            cmp -s "$tmp" "$ROOT/$out" || {
                printf 'theme: out of date: %s\n' "$out" >&2
                stale=1
            }
            rm -f "$tmp"
        else
            mv "$tmp" "$ROOT/$out"
            printf '  %s\n' "$out"
        fi
    done <<< "$ISG_TARGETS"
done

if [ "$stale" != 0 ]; then
    printf 'theme: run `bash theme/generate.sh` and commit the result\n' >&2
    exit 3
fi

if [ "$check_only" = 1 ]; then
    printf 'theme: generated files are up to date\n'
fi
