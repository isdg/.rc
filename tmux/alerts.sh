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

list=$(tmux list-windows -a -F "$fmt" | awk -F'\t' '
{
    target = $1; name = $2
    act = $3; sil = $4; bel = $5; mon_a = $6; mon_s = $7; panes = $8

    # Silence outranks activity for the same reason the status bar does it:
    # both flags stay raised once set, and a window that has stopped should
    # say so rather than report the burst before it.
    if (bel == 1)      { rank = 0; sym = "!"; what = "bell" }
    else if (sil == 1) { rank = 1; sym = "~"; what = "stopped" }
    else if (act == 1) { rank = 2; sym = "*"; what = "running" }
    else if (mon_a == 1 || mon_s + 0 > 0) { rank = 3; sym = "\xc2\xb7"; what = "watching" }
    else               { rank = 4; sym = " "; what = "" }

    printf "%d\t%s\t%s %-9s %-22s %s\n", rank, target, sym, what, target, name
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
