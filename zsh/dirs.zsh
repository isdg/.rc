# ── directory navigation ──
# Vendored from oh-my-zsh's lib/directories.zsh (MIT) when oh-my-zsh was
# dropped, because these were in use. Verbatim except the four setopts it also
# set (auto_cd, auto_pushd, pushd_ignore_dups, pushd_minus) — .zshrc's init
# block already sets those, and 1-9 below depend on them.
#
# Two things worth knowing, both inherited as-is:
#   - `..` is deliberately not defined, exactly as in oh-my-zsh: auto_cd handles
#     it, so typing `..` still works.
#   - `...` and friends are GLOBAL aliases, so they expand in any argument
#     position, not just after cd: `vim ...`, `cp file ....`. They match whole
#     words only, so `.../file` stays literal — same as under oh-my-zsh.

alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias -- -='cd -'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

alias md='mkdir -p'
alias rd=rmdir

function d () {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n 10
  fi
}
compdef _dirs d

# List directory contents
alias lsa='ls -lah'
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -lAh'
