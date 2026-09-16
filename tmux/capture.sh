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

# Both nvim lines are omni's own, read off a live capture rather than guessed,
# so the popup and the window open the same editor. -e keeps the colour that
# baleia turns into highlights; plain asks for none, which is the whole
# difference between the two keys.
if [ "$pager" = "plain" ]; then
    tmux capture-pane -p -S - -t "$pane" > "$f"
    open="nvim -n -c \"normal! 1Gzt\" \"$f\""
else
    tmux capture-pane -p -e -S - -t "$pane" > "$f"
    open="nvim -n -c \"lua pcall(function() require([[baleia]]).setup().once(0) end)\" \
        -c \"normal! 1Gzt\" \"$f\""
fi

# -B is what makes the size exact: a bordered popup is two cells smaller each
# way. -x/-y are client coordinates and pane_left/pane_top window ones, which
# agree only while the status line is at the bottom, as it is here.
eval "$(tmux display -p -t "$pane" \
    'w=#{pane_width} h=#{pane_height} x=#{pane_left} y=#{pane_top}')"

# display-popup blocks until the popup closes, so the cleanup below is reached
# when the reader quits -- measured, not assumed.
tmux display-popup -B -E -w "$w" -h "$h" -x "$x" -y "$y" "$open"
rm -f "$f"
