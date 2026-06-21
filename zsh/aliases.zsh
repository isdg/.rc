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

# Palace notes — thin `plc` wrappers now ship with the dotfiles. PALACE_DIR
# points at the vault (decrypted into ~/palace/palace/notes).
export PALACE_DIR="$HOME/palace/palace"
source "$HOME/.dotfiles/zsh/palace.zsh"
