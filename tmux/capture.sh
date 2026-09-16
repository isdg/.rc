#!/bin/sh
# The pane's scrollback, opened for reading. Bound to prefix j (colour, via
# baleia) and prefix J (plain) in .tmux.conf, which passes the pager as $1.
#
# A script rather than two inline run-shell bodies because the two keys differ
# by two lines out of fifteen, and .tmux.conf keeps the bindings either way.
set -eu

pager=${1:-nvim}
# The binding passes #{pane_id}, expanded by tmux at press time. Not TMUX_PANE:
# run-shell leaves whatever the server was started with in place, which is a
# stale pane -- or another server's -- as soon as one is inherited. Measured.
pane=${2:-$(tmux display -p '#{pane_id}')}

# @capture-overlay off hands back to omni, which opens the capture in its own
# window. On, the same capture goes into a popup pinned over the pane below.
if [ "$(tmux show -gv @capture-overlay 2>/dev/null || true)" != "on" ]; then
    omni=$(command -v omni || echo "$HOME/.cargo/bin/omni")
    exec "$omni" capture --pager "$pager"
fi

f=$(mktemp "${TMPDIR:-/tmp}/tmux-pane.XXXXXX")

# -B is what makes the size exact: a bordered popup is two cells smaller each
# way. -x/-y are client coordinates and pane_left/pane_top window ones, which
# agree only while the status line is at the bottom, as it is here.
# scroll_position is how far copy-mode is scrolled back, and empty outside it.
eval "$(tmux display -p -t "$pane" \
    'w=#{pane_width} h=#{pane_height} x=#{pane_left} y=#{pane_top} s=#{scroll_position}')"
case ${s:-0} in ''|*[!0-9]*) s=0 ;; esac

# Land on the screenful the pane is showing, not on the top of its history: the
# popup sits exactly over that text, so opening anywhere else reads as the pane
# jumping. Gzb is the bottom of the capture, then back up by however far
# copy-mode had already scrolled. omni's own 1Gzt is what this replaces.
# An `[ … ] && pos=…` one-liner would abort the script under set -e every time
# the test failed, which is every capture taken from a pane at its bottom.
pos="normal! Gzb"
if [ "$s" -gt 0 ]; then
    pos="normal! G${s}kzb"
fi

# No gutter: this is pane output, not a file, and every column one of these takes
# is a column the text shifts by — which the popup shows as the pane's own lines
# moving sideways under it. signcolumn goes for the same reason numbers do
# (options.lua keeps it on globally), and setlocal so a file opened from in here
# still gets the usual editing furniture.
bare="setlocal nonumber norelativenumber signcolumn=no"

# Same argument vertically: nvim's statusline and cmdline are two rows the pane
# does not have, so with them the capture's text sits two lines off the text it
# covers. Both are global options, hence set rather than setlocal. Typing : still
# opens a cmdline over the last row when it is needed.
chrome="set laststatus=0 cmdheight=0"

# Both nvim lines are otherwise omni's, read off a live capture rather than
# guessed. -e keeps the colour that baleia turns into highlights; plain asks for
# none, which is the whole difference between the two keys.
if [ "$pager" = "plain" ]; then
    tmux capture-pane -p -S - -t "$pane" > "$f"
    open="nvim -n -c \"$chrome\" -c \"$bare\" -c \"$pos\" \"$f\""
else
    tmux capture-pane -p -e -S - -t "$pane" > "$f"
    open="nvim -n -c \"lua pcall(function() require([[baleia]]).setup().once(0) end)\" \
        -c \"$chrome\" -c \"$bare\" -c \"$pos\" \"$f\""
fi

# The popup is the pane's twin down to the cell, so nothing inside it says which
# of the two you are reading. -B leaves no border to hang -T on, so the status
# line carries it: the window wears capture: while the capture is up.
name=$(tmux display -p -t "$pane" '#{window_name}')
auto=$(tmux show -wqv -t "$pane" automatic-rename || true)

# rename-window turns automatic-rename off for that window as a side effect, so
# putting the name back means restoring the option, not retyping the old name --
# unless it was already off, which is someone having named this window by hand.
restore() {
    rm -f "$f"
    if [ "${auto:-on}" = "on" ]; then
        tmux set -wu -t "$pane" automatic-rename
    else
        tmux rename-window -t "$pane" "$name"
    fi
}
trap restore EXIT INT TERM

tmux rename-window -t "$pane" "capture:$name"
# display-popup blocks until the popup closes, so restore runs when the reader
# quits -- measured, not assumed.
tmux display-popup -B -E -w "$w" -h "$h" -x "$x" -y "$y" "$open"
