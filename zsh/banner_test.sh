#!/usr/bin/env bash
# Renders banner.zsh in mini mode under a fixed mascot and info lines, and
# checks the two lines it draws.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

LC_ALL="$(locale -a | grep -i -E '^(en_US|C)\.utf-?8$' | sed -n 1p)"
export LC_ALL HOME="$tmp"

render() {
    BANNER_MODE="$1" zsh -f -c '
        source "$1/zsh/banner.zsh"
        BANNER_LOG_FUNCS=( fake_shell fake_log )
        fake_shell() { banner_info "zsh 9.9 · 42 ms" }
        fake_log() { banner_log "a log line" }
        _banner_mascot=( "       ▼ qB" "tape" "δ(qB,0)=⟨A,1,L⟩" )
        _banner_info_lines=( "%B%n%b@box · local" "Mon 01 Jan" )
        cd ~ && banner_render
    ' _ "$repo" | sed $'s/\e\\[[0-9;]*m//g'
}

fail=0
check() {
    if [[ "$2" == "$3" ]]; then
        echo "ok   $1"
    else
        printf 'FAIL %s\n  want: %q\n  got:  %q\n' "$1" "$3" "$2"
        fail=1
    fi
}

user="$(id -un)"
want=$'\n'"  ▼ qB  δ(qB,0)=⟨A,1,L⟩  $user@box · local"$'\n'
want+=$'                         zsh 9.9 · 42 ms\n'
check "mini nologs: head, δ, identity and shell" \
    "$(render 'mini nologs')"$'\n' "$want"

check "mini beats nomascot" \
    "$(render 'mini nologs nomascot')"$'\n' "$want"

want+=$'\n    › a log line\n'
check "mini alone keeps the logs" "$(render mini)"$'\n' "$want"

identity="$(zsh -f -c '
    source "$1/zsh/banner.zsh"
    print -r -- "${_banner_info_lines[1]%%@*}@"
' _ "$repo")"
check "identity joins user and host with @" "$identity" '%B%n%b@'

exit "$fail"
