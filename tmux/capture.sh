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

# The capture itself lives in $TMPDIR, so without this nvim would sit there and
# every relative path in the output -- which is most of what a build or a test
# run prints -- would resolve nowhere. Fetched on its own line, not through the
# eval above: a directory may contain spaces, those four numbers may not.
cwd=$(tmux display -p -t "$pane" '#{pane_current_path}')

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

# P for promote: the popup is for a look, and sometimes a look turns into work.
# P closes it and reopens the same capture as a pane, at the line being read.
# A popup swallows the prefix, so this has to be a key inside nvim rather than a
# tmux binding; buffer-local, and P because paste-before is the one normal-mode
# key a pane's output has no use for. The line number doubles as the flag file.
promote="$f.promote"
promote_map="lua vim.keymap.set('n','P',function()
    vim.fn.writefile({tostring(vim.fn.line('.'))},'$promote') vim.cmd('qa!') end,
    {buffer=true,desc='capture: promote to a pane'})"

# The nvim call is otherwise omni's, read off a live capture rather than guessed.
# -e keeps the colour that baleia turns into highlights; plain asks for none,
# which is the whole difference between the two keys.
if [ "$pager" = "plain" ]; then
    tmux capture-pane -p -S - -t "$pane" > "$f"
    colour=""
else
    tmux capture-pane -p -e -S - -t "$pane" > "$f"
    colour="-c \"lua pcall(function() require([[baleia]]).setup().once(0) end)\""
fi
open="nvim -n $colour -c \"$chrome\" -c \"$bare\" -c \"$promote_map\" -c \"$pos\" \"$f\""

# The popup is the pane's twin down to the cell, so nothing inside it says which
# of the two you are reading. -B leaves no border to hang -T on, so the status
# line carries it: @capture makes the window render as (name), in bold, for as
# long as the capture is up (window-status-format in .tmux.conf).
#
# A flag rather than a renamed window, which is what this used to be: the name
# goes on saying what is running, and nothing has to be put back afterwards --
# rename-window turns automatic-rename off as a side effect, so restoring it
# meant remembering both the name and whether the option had been on.
keep=0 # set when P promotes the capture, which hands the file to a pane
restore() {
    if [ "$keep" = 0 ]; then
        rm -f "$f"
    fi
    tmux set -wu -t "$pane" @capture
}
trap restore EXIT INT TERM

tmux set -w -t "$pane" @capture 1
# display-popup blocks until the popup closes, so restore runs when the reader
# quits -- measured, not assumed.
tmux display-popup -B -E -d "$cwd" -w "$w" -h "$h" -x "$x" -y "$y" "$open"

# P wrote the line it was on, so the pane opens looking at the same text. Split
# below rather than beside: the new pane keeps the source pane's width, and the
# capture's lines were wrapped to exactly that width when tmux rendered them.
# The origin pane keeps its shell and its scrollback; only the window's geometry
# gives way, which is the one thing a second pane cannot avoid asking for.
# chrome stays out of it -- a pane covers nothing, so a statusline costs nothing
# -- and the temp file now belongs to the pane, as omni's window owns its own.
if [ -f "$promote" ]; then
    keep=1
    line=$(cat "$promote")
    rm -f "$promote"
    tmux split-window -v -t "$pane" -c "$cwd" \
        "nvim -n $colour -c \"$bare\" -c \"normal! ${line}Gzz\" \"$f\""
fi
