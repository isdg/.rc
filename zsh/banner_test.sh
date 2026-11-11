#!/usr/bin/env bash
# Renders banner.zsh in mini mode under a fixed mascot and info lines, and
# checks the two lines it draws; then the real info lines of a local login.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

LC_ALL="$(locale -a | grep -i -E '^(en_US|C)\.utf-?8$' | sed -n 1p)"
export LC_ALL HOME="$tmp"
unset SSH_CONNECTION SSH_TTY SUDO_USER _BANNER_T0

render() {
    BANNER_MODE="$1" zsh -f -c '
        source "$1/zsh/banner.zsh"
        BANNER_LOG_FUNCS=( fake_shell fake_log )
        fake_shell() { _banner_ms=42; banner_info "local · zsh 9.9 · 42 ms" }
        fake_log() { banner_log "a log line" }
        _banner_mascot=( "       ▼ qB" "tape" "δ(qB,0)=⟨A,1,L⟩" )
        _banner_info_lines=( "%B%n%b@box" "Mon 01 Jan" )
        _banner_session=local
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
want=$'\n'"  ▼ qB  δ(qB,0)=⟨A,1,L⟩  $user@box"$'\n'
want+=$'                         local · 42 ms\n'
check "mini nologs: head, δ, identity, kind and time" \
    "$(render 'mini nologs')"$'\n' "$want"

check "mini beats nomascot" \
    "$(render 'mini nologs nomascot')"$'\n' "$want"

want+=$'\n    › a log line\n'
check "mini alone keeps the logs" "$(render mini)"$'\n' "$want"

lines="$(zsh -f -c '
    source "$1/zsh/banner.zsh"
    info_shell
    print -rl -- "${_banner_info_lines[@]}"
' _ "$repo")"
host="$(zsh -f -c 'print -r -- ${HOST%%.*}')"
version="$(zsh -f -c 'print -r -- $ZSH_VERSION')"
want="%B%n%b@$host"$'\n'"%D{%a %d %b %Y · %H:%M}"$'\n'
want+="local · zsh $version"
check "local: user@host, then the kind on the shell line" "$lines" "$want"

kind="$(SUDO_USER=root zsh -f -c '
    source "$1/zsh/banner.zsh"
    _banner_sudo_origin() { }
    banner_session_info
' _ "$repo")"
check "sudo on a local box: via, no kind" "$kind" "via root"

exit "$fail"
