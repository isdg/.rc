#!/usr/bin/env bash
# Loads, runs and inspects the launchd jobs beside this script. Nothing
# loads them for you: a job runs only after `agents.sh load NAME`.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agents="$HOME/Library/LaunchAgents"
logs="${RC_JOB_LOG_DIR:-$HOME/Library/Logs/rc}"
domain="gui/$(id -u)"

names() {
    local p
    for p in "$dir"/com.local.*.plist; do
        p="${p##*/com.local.}"
        echo "${p%.plist}"
    done
}

usage() {
    local me="${0##*/}"
    echo "usage: $me list" >&2
    echo "       $me load|unload|run|status|log NAME" >&2
    echo "jobs:  $(names | tr '\n' ' ')" >&2
    exit 2
}

field() { # print-output key
    awk -F' = ' -v k="$2" '$1 == "\t" k { print $2; exit }' <<< "$1"
}

list() {
    local name out
    printf '%-16s %-8s %-12s %s\n' JOB LOADED STATE 'LAST EXIT'
    for name in $(names); do
        if out="$(launchctl print "$domain/com.local.$name" 2>/dev/null)"
        then
            printf '%-16s %-8s %-12s %s\n' "$name" yes \
                "$(field "$out" state)" "$(field "$out" 'last exit code')"
        else
            printf '%-16s %s\n' "$name" no
        fi
    done
}

[ "$#" -ge 1 ] || usage
cmd="$1"
[ "$cmd" = list ] && { list; exit; }
[ "$#" -eq 2 ] || usage
name="$2"
label="com.local.$name"
src="$dir/$label.plist"
dst="$agents/$label.plist"
[ -f "$src" ] || { echo "agents.sh: no job $name" >&2; usage; }

case "$cmd" in
    load)
        if [ -e "$dst" ] && [ "$(readlink "$dst")" != "$src" ]; then
            echo "agents.sh: $dst exists and is not ours" >&2
            exit 1
        fi
        mkdir -p "$agents"
        ln -sfn "$src" "$dst"
        launchctl bootout "$domain/$label" 2>/dev/null || true
        launchctl bootstrap "$domain" "$dst"
        echo "loaded $label"
        ;;
    unload)
        launchctl bootout "$domain/$label" 2>/dev/null || true
        [ "$(readlink "$dst")" = "$src" ] && rm "$dst"
        echo "unloaded $label"
        ;;
    run)    launchctl kickstart "$domain/$label" ;;
    status) launchctl print "$domain/$label" ;;
    log)    tail -n 40 "$logs/$name.log" ;;
    *)      usage ;;
esac
