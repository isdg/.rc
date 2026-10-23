#!/usr/bin/env bash
# gd/gr/gi/gy, the LSP picker and the rust-analyzer setup, headless on a
# pinned tokio with this checkout's nvim config. --quick runs the focused
# checks only (about a minute); the full suite takes about ten.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
nvim_dir=$(cd "$here/../.." && pwd)
cache=${XDG_CACHE_HOME:-$HOME/.cache}/nvim-lsp-test
tokio=$cache/tokio
quick=0
[ "${1:-}" = "--quick" ] && quick=1

if [ ! -d "$tokio" ]; then
    mkdir -p "$cache"
    git -c advice.detachedHead=false clone -q --depth 1 \
        --branch tokio-1.54.1 \
        https://github.com/tokio-rs/tokio "$tokio"
fi

# This checkout becomes nvim's config dir; the theme file only sets colours.
out=$(mktemp -d "$cache/run.XXXXXX")
mkdir -p "$out/xdg/isg"
ln -s "$nvim_dir" "$out/xdg/nvim"
theme=${XDG_CONFIG_HOME:-$HOME/.config}/isg/theme
if [ -f "$theme" ]; then cp "$theme" "$out/xdg/isg/"; fi

status=0
(
    cd "$tokio"
    XDG_CONFIG_HOME=$out/xdg LSP_TEST_OUT=$out LSP_TEST_QUICK=$quick \
        nvim --headless -c "luafile $here/main.lua"
) || status=$?

# Servers this run started under lspmux would otherwise idle for hours.
if command -v lspmux >/dev/null && lspmux status >/dev/null 2>&1; then
    lspmux status | awk '/^  pid:/ { pid = $2 } /^  path:/ { print pid, $2 }' |
        tr -d '"' | while read -r pid path; do
            case $path in "$tokio"*) kill "$pid" 2>/dev/null || true ;; esac
        done || true
fi
exit "$status"
