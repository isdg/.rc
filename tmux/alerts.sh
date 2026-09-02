#!/bin/sh
# alerts.sh — every window on this server, what its alert is doing, jump to one.
#
# The picker behind C-b C-b A. The status bar carries the same information in
# its sweep, clipped to 28 columns and with no way to act on it; this is the
# unclipped version you can select from. Built to sit next to omni's pickers
# rather than beside them: display-popup + fzf, and fzf reads its palette from
# FZF_DEFAULT_OPTS_FILE, which .tmux.conf puts in the server environment for
# exactly this reason — a popup runs under default-shell and inherits it, so the
# theme follows a light/dark toggle without this script knowing anything.
#
# Two states are worth telling apart and tmux only names one of them. A window
# whose monitors are armed but which has not tripped yet is *watching*; one that
# has tripped is running, stopped or belled. The bar cannot show watching (a
# window with no flag is indistinguishable from an unarmed one there), which is
# half the reason this exists — after arming three windows the useful question
# is usually "which ones am I still waiting on".
#
# The sort puts anything flagged above anything merely watching, and both above
# the rest, so the answer is the first line rather than somewhere in a list of
# forty.

set -eu

# One field per tab: the target is first so awk can hand it to fzf as a hidden
# key, and every flag the display needs comes from the same call rather than a
# tmux round-trip per window.
fmt='#{session_name}:#{window_index}	#{window_name}	#{window_activity_flag}	#{window_silence_flag}	#{window_bell_flag}	#{monitor-activity}	#{monitor-silence}	#{window_panes}'

# The status trails the name rather than leading the row. Most windows are not
# armed most of the time, so a leading status column is a blank gutter down the
# whole list; putting it last leaves the common case looking like omni's window
# picker and lets an alert stick out to the right of it.
#
# Column widths come from the data, in END, because they cannot be known before
# the last row is read — hardcoding them let agents-livekit-stack:2 run into its
# own window name.
list=$(tmux list-windows -a -F "$fmt" | awk -F'\t' '
{
    target = $1; name = $2
    act = $3; sil = $4; bel = $5; mon_a = $6; mon_s = $7

    # Silence outranks activity for the same reason the status bar does it:
    # both flags stay raised once set, and a window that has stopped should
    # say so rather than report the burst before it.
    if (bel == 1)      { r = 0; s = "!"; w = "bell" }
    else if (sil == 1) { r = 1; s = "~"; w = "stopped" }
    else if (act == 1) { r = 2; s = "*"; w = "running" }
    else if (mon_a == 1 || mon_s + 0 > 0) { r = 3; s = "\xc2\xb7"; w = "watching" }
    else               { r = 4; s = "";  w = "" }

    n++; rk[n] = r; tg[n] = target; nm[n] = name; sy[n] = s; wh[n] = w
    if (length(target) > tw) tw = length(target)
    if (length(name)   > nw) nw = length(name)
}
END {
    for (i = 1; i <= n; i++) {
        line = sprintf("%-*s  %-*s  %s %s", tw, tg[i], nw, nm[i], sy[i], wh[i])
        sub(/ +$/, "", line)
        printf "%d\t%s\t%s\n", rk[i], tg[i], line
    }
}' | sort -k1,1n | cut -f2-)

[ -n "$list" ] || { printf 'no windows\n'; sleep 1; exit 0; }

# --with-nth 2.. hides the target column from view while leaving it in {1} for
# the preview and the selection. --preview tails the pane rather than showing
# all of it: the question is what the window is doing now.
#
# No --preview-window and no --color: fzf/opts-active.conf owns both, and is
# read by every fzf on the machine through $FZF_DEFAULT_OPTS_FILE. Setting
# either here would make this picker the one that ignores a theme toggle.
sel=$(printf '%s\n' "$list" | fzf \
    --delimiter='\t' \
    --with-nth=2.. \
    --header='alerts · enter to jump' \
    --preview='tmux capture-pane -p -t {1} | tail -n 40') || exit 0

target=${sel%%	*}
[ -n "$target" ] || exit 0

# switch-client moves the attached client to the session, select-window then
# picks the window inside it — one without the other lands you in the right
# session on the wrong window, or does nothing at all across a session boundary.
tmux switch-client -t "${target%%:*}"
tmux select-window -t "$target"
