alias n='nvim'
alias n.='nvim .'
np() { local f; f=$(fzf) && nvim "$f"; }
alias t='tig'
alias ts='tig status'
alias v='vim'
alias v.='vim .'
alias c='claude'
alias tm='tmux'
alias os='orchbus'   # cockpit for triaging Claude Code sessions
alias tt='bash "${ISGRC:-$HOME/.rc}/toggle_theme.sh"'   # toggle light/dark
alias ww='bash "${ISGRC:-$HOME/.rc}/width.sh"'          # cycle ghostty padding-x

# gjobs — cross-terminal "jobs". The `jobs` builtin only sees the current
# shell's job table, so this shows every terminal-attached process grouped by
# tty, then every tmux pane across all sockets (each pane = a shell + the
# command it's running). `ps -x` is your processes; `??` (no tty) rows are
# filtered out.
gjobs() {
  echo "── your processes by terminal ──────────────────────────────"
  ps -xo tty,pid,pgid,stat,command | awk 'NR==1 || $1 != "??"' | { read -r h; echo "$h"; sort; }
  echo
  echo "── tmux panes (all sockets) ────────────────────────────────"
  local dir="${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)" sock found=0
  for sock in "$dir"/*(=N); do
    tmux -L "${sock:t}" list-panes -a \
      -F "  [${sock:t}] #{session_name}:#{window_index}.#{pane_index}  #{pane_pid}  #{pane_current_command}" \
      2>/dev/null && found=1
  done
  (( found )) || echo "  (no tmux sockets / servers)"
}

# gh: page only when output exceeds one screen. less -F quits immediately if it
# fits (so short output prints straight to stdout), -X leaves it on screen
# instead of clearing. Overrides gh's default pager without touching ~/.config/gh.
export GH_PAGER='less -FX'

# gh/glamour markdown theme. Inside tmux the OSC 11 background-colour query is
# answered by tmux itself (with its dark default) rather than reaching the outer
# terminal, so glamour's `auto` style renders dark in a light terminal even with
# allow-passthrough on. Pin the style to our light/dark marker instead — its
# values (`light`/`dark`) are glamour's own style names. Re-source (or open a new
# shell) after toggle_theme.sh flips the marker to follow it.
export GLAMOUR_STYLE="$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/isg/theme" 2>/dev/null || echo light)"

# k9s: force a terminfo entry its TUI library can actually use, but only inside
# tmux. Outside tmux k9s renders the skin exactly; inside it, everything came out
# blue-grey.
#
# Measured rather than guessed: the body background sampled as #bcc0cc and the
# selected row as #456eff. Those are palette indexes 15 and 12 — i.e. the skin's
# #fafafa and #007acc quantized to the nearest of the standard 16 ANSI colours,
# with Ghostty then painting those two slots from our own ramp (theme/palette.sh
# ISG_ANSI_15 / ISG_ANSI_12). So k9s was emitting 16-colour output, which is also
# why the wash looked blue rather than plain grey.
#
# The cause is tcell's terminfo lookup, not a missing file:
# /usr/share/terminfo/74/tmux-256color exists and ncurses finds it (`infocmp
# tmux-256color` works), and COLORTERM=truecolor is already set in the pane —
# neither is enough. xterm-256color is an entry tcell handles, and with COLORTERM
# present it then goes to 24-bit and the skin renders exactly.
#
# Scoped on purpose. Only k9s is affected, because only k9s uses tcell — nvim,
# bat, tig and fzf are all correct in tmux already. In particular do NOT "fix"
# this by changing default-terminal in tmux/.tmux.conf: that would change TERM for
# every program to fix one, and tmux wants a tmux-*/screen-* entry inside, which
# together with `terminal-features ',*:RGB'` is what gives everything else its
# truecolor.
k9s() {
  if [[ -n $TMUX ]]; then
    TERM=xterm-256color command k9s "$@"
  else
    command k9s "$@"
  fi
}

# Palace notes — thin `plc` wrappers now ship with the dotfiles. The vault path
# is persisted in ~/.plcrc; ask `plc config` for it instead of hardcoding here,
# so there is exactly one source of truth.
#
# `env -u PALACE_DIR` matters: `plc config` echoes back $PALACE_DIR when it is
# already set and only falls back to ~/.plcrc when it is not. Without it this
# line re-affirms whatever it inherited instead of re-deriving, so one stale
# value (a tmux global env snapshot, a long-lived parent process) launders
# itself through every new shell indefinitely.
export PALACE_DIR="$(env -u PALACE_DIR plc config 2>/dev/null)"
source "${ISGRC:-$HOME/.rc}/zsh/palace.zsh"

# Machine-local, gitignored aliases/functions (work-specific helpers, private
# repo names, employer paths). Never published; source it only if it exists.
[ -f "${ISGRC:-$HOME/.rc}/zsh/aliases.ignored.zsh" ] \
   && source "${ISGRC:-$HOME/.rc}/zsh/aliases.ignored.zsh"
