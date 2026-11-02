#!/usr/bin/env bash
# 03-completion runs the full compinit only once its dump is a day old. That
# run must leave the dump fresh even when compinit finds nothing to rewrite,
# or every later shell pays for the full fpath scan and compaudit.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp"
dump="$HOME/.zcompdump-lite"

start() {
    zsh -f -c "source '$repo/zsh/rc.d/01-options.zsh'
               source '$repo/zsh/rc.d/03-completion.zsh'"
}
mtime() {
    zsh -f -c 'zmodload -F zsh/stat b:zstat; zstat +mtime -- $1' zsh "$dump"
}
ago() {
    zsh -f -c 'zmodload zsh/datetime
               strftime %Y%m%d%H%M.%S $(( EPOCHSECONDS - $1 ))' zsh "$1"
}
now() { zsh -f -c 'zmodload zsh/datetime; print $EPOCHSECONDS'; }

fails=0
check() {
    local what="$1" want="$2" got="$3"
    if [ "$got" = "$want" ]; then
        echo "ok   $what"
    else
        echo "FAIL $what: want '$want', got '$got'"
        fails=$((fails + 1))
    fi
}

start
check "the first shell writes the dump" yes \
    "$([ -s "$dump" ] && echo yes || echo no)"

# Same fpath as the run that wrote it, so compinit itself rewrites nothing.
touch -t "$(ago $((2 * 86400)))" "$dump"
start
check "a full scan leaves the dump fresh" yes \
    "$([ $(( $(now) - $(mtime) )) -lt 86400 ] && echo yes || echo no)"

touch -t "$(ago 3600)" "$dump"
before="$(mtime)"
start
check "a fresh dump is left untouched" "$before" "$(mtime)"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
