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
        fake_shell() {
            _banner_rc=9.9.9 _banner_ms=42
            banner_info ".rc 9.9.9 · 42 ms · local"
        }
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
want+=$'                         .rc 9.9.9 · 42 ms · local\n'
check "mini nologs: head, δ, identity, version, time and kind" \
    "$(render 'mini nologs')"$'\n' "$want"

check "mini beats nomascot" \
    "$(render 'mini nologs nomascot')"$'\n' "$want"

want+=$'\n    › a log line\n'
check "mini alone keeps the logs" "$(render mini)"$'\n' "$want"

want=$'\n'"  ▼ qB  .rc 9.9.9 · $user@box · 42 ms"$'\n'
check "tiny nologs: head, version, identity and time" \
    "$(render 'tiny nologs')"$'\n' "$want"

check "tiny beats mini and nomascot" \
    "$(render 'tiny mini nologs nomascot')"$'\n' "$want"

want+=$'\n    › a log line\n'
check "tiny alone keeps the logs" "$(render tiny)"$'\n' "$want"

info() {
    ISGRC="$1" zsh -f -c '
        source "$1/zsh/banner.zsh"
        info_shell
        info_date
        print -rl -- "${_banner_info_lines[@]}"
    ' _ "$repo"
}
host="$(zsh -f -c 'print -r -- ${HOST%%.*}')"
mkdir "$tmp/rc"
echo 9.9.9 > "$tmp/rc/VERSION"
want="%B%n%b@$host"$'\n'".rc 9.9.9 · local"$'\n'
want+="%D{%a %d %b %Y · %H:%M}"
check "local: user@host, version and kind on the shell line, the date" \
    "$(info "$tmp/rc")" "$want"

want="%B%n%b@$host"$'\n'"local"$'\n'"%D{%a %d %b %Y · %H:%M}"
check "no VERSION: the shell line drops the version" \
    "$(info "$tmp")" "$want"

# line 4 is the date, left out so a minute turning over can't fail the test
redraw="$(ISGRC="$tmp/rc" BANNER_MODE=tiny zsh -f -c '
    mkdir -p $ISGRC/zsh && cp "$1/zsh/banner.zsh" $ISGRC/zsh/
    source $ISGRC/zsh/banner.zsh
    rcbanner nomascot nologs
    print -r -- "mode $BANNER_MODE"
' _ "$repo" | sed -e $'s/\e\\[[0-9;]*m//g' -e 4d)"
want=$'\n'"    › $user@$host"$'\n'"    › .rc 9.9.9 · local"$'\n\n'"mode tiny"
check "rcbanner: redraws in the modes given, leaves BANNER_MODE" \
    "$redraw" "$want"

kind="$(SUDO_USER=root zsh -f -c '
    source "$1/zsh/banner.zsh"
    _banner_sudo_origin() { }
    banner_session_info
' _ "$repo")"
check "sudo on a local box: via, no kind" "$kind" "via root"

exit "$fail"
