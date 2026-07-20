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

# gh: page only when output exceeds one screen. less -F quits immediately if it
# fits (so short output prints straight to stdout), -X leaves it on screen
# instead of clearing. Overrides gh's default pager without touching ~/.config/gh.
export GH_PAGER='less -FX'

# Palace notes — thin `plc` wrappers now ship with the dotfiles. The vault path
# is persisted in ~/.plcrc; ask `plc config` for it instead of hardcoding here
# (fall back to the default while bootstrapping, before `plc` is installed).
export PALACE_DIR="$(plc config 2>/dev/null || echo "$HOME/palace/palace")"
source "${ISG_DOTFILES:-$HOME/.dotfiles}/zsh/palace.zsh"

# Machine-local, gitignored aliases/functions (work-specific helpers, private
# repo names, employer paths). Never published; source it only if it exists.
[ -f "${ISG_DOTFILES:-$HOME/.dotfiles}/zsh/aliases.ignored.zsh" ] \
   && source "${ISG_DOTFILES:-$HOME/.dotfiles}/zsh/aliases.ignored.zsh"
