log() {
  local f="$HOME/logs/$(date +%Y%m%d-%H%M%S).log"
  mkdir -p "$HOME/logs"
  echo "logging to $f"
  script -q "$f"
}

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

# Palace notes — thin `plc` wrappers now ship with the dotfiles. The vault path
# is persisted in ~/.plcrc; ask `plc config` for it instead of hardcoding here
# (fall back to the default while bootstrapping, before `plc` is installed).
export PALACE_DIR="$(plc config 2>/dev/null || echo "$HOME/palace/palace")"
source "${ISG_DOTFILES:-$HOME/.dotfiles}/zsh/palace.zsh"

# Machine-local, gitignored aliases/functions (work-specific helpers, private
# repo names, employer paths). Never published; source it only if it exists.
[ -f "${ISG_DOTFILES:-$HOME/.dotfiles}/zsh/aliases.ignored.zsh" ] \
   && source "${ISG_DOTFILES:-$HOME/.dotfiles}/zsh/aliases.ignored.zsh"
