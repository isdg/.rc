#!/usr/bin/env bash
# Exercises the window jumplist (rc.d/16-jumplist.conf, jumplist.sh) on a
# throwaway tmux server, through a control-mode client.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
fails=0

check() {
    local what="$1" want="$2" got="$3"
    if [ "$got" = "$want" ]; then
        echo "ok   $what"
    else
        echo "FAIL $what: want $want, got $got"
        fails=$((fails + 1))
    fi
}

unset TMUX
export HOME="$tmp/home" TMUX_TMPDIR="$tmp"
mkdir -p "$HOME/.config/rc/tmux"
ln -s "$repo/tmux/.tmux.conf" "$HOME/.tmux.conf"
ln -s "$repo/tmux/rc.d/16-jumplist.conf" "$HOME/.config/rc/tmux/"
trap 'tmux kill-server 2>/dev/null || true; rm -rf "$tmp"' EXIT

tmux new -d -s a -n A \; new-window -n B \; new-window -n C \; \
    new -d -s b -n D
sleep 30 | tmux -C attach -t a >/dev/null &
for _ in $(seq 50); do
    client="$(tmux list-clients -F '#{client_name}')"
    [ -n "$client" ] && break
    sleep 0.1
done

at() { tmux display -c "$client" -p '#{window_name}'; }
go() { tmux switch-client -c "$client" -t "=$1"; }
jump() {
    sh "$repo/tmux/jumplist.sh" "$1" "$client" \
        "$(tmux display -c "$client" -p '#{@seen}')"
    at
}
# The keys run the script with -b, so wait for the window to change.
key() {
    local before
    before="$(at)"
    tmux send-keys -K -c "$client" C-b "$1"
    for _ in $(seq 50); do
        [ "$(at)" != "$before" ] && break
        sleep 0.1
    done
    at
}

go a:A; go a:B; go a:C; go b:D

check "back crosses sessions" C "$(jump back)"
check "back" B "$(jump back)"
check "back" A "$(jump back)"
check "back stops at the oldest" A "$(jump back)"
check "forward" B "$(jump forward)"
check "forward" C "$(jump forward)"
check "forward" D "$(jump forward)"
check "forward stops at the newest" D "$(jump forward)"

jump back >/dev/null
jump back >/dev/null
go a:A
check "back returns to the window left" B "$(jump back)"
check "a jump's landing kept its place" D "$(jump back)"
check "back" C "$(jump back)"

# C is the oldest now, so the keys start by stepping forward.
check "prefix C-o goes forward" D "$(key C-o)"
check "prefix Tab goes back" C "$(key Tab)"
check "prefix C-o again" D "$(key C-o)"
check "prefix C-i goes back" C "$(key C-i)"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
