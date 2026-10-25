#!/bin/sh
# One step through the window jumplist that rc.d/16-jumplist.conf stamps:
#   jumplist.sh back|forward <client> <@seen of the client's window>
set -eu

dir="$1" client="$2" cur="$3"

# The nearest stamp below the current one going back, above it going forward.
# An unstamped current window sits past the newest, so back takes the newest.
target="$(tmux list-windows -a -F '#{window_id} #{@seen}' |
    awk -v dir="$dir" -v cur="$cur" '
        NF < 2 { next }
        dir == "back" && (cur == "" || $2 < cur + 0) &&
            (id == "" || $2 > best) { best = $2 + 0; id = $1 }
        dir == "forward" && cur != "" && $2 > cur + 0 &&
            (id == "" || $2 < best) { best = $2 + 0; id = $1 }
        END { print id }')"

if [ -z "$target" ]; then
    case "$dir" in
        back) end=oldest ;;
        *) end=newest ;;
    esac
    tmux display-message -c "$client" "jumplist: at the $end window"
    exit 0
fi

tmux set -g @jnav "$target" \; switch-client -c "$client" -t "$target"
