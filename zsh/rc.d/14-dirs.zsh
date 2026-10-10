# ── directory navigation ──
# Vendored from oh-my-zsh's lib/directories.zsh (MIT) when oh-my-zsh was
# dropped, because these were in use. Verbatim except the four setopts it also
# set (auto_cd, auto_pushd, pushd_ignore_dups, pushd_minus) — .zshrc's init
# block sets all but auto_cd, and 1-9 below depend on the pushd ones.
#
# The upward aliases. oh-my-zsh left `..` to auto_cd and made `...` and friends
# GLOBAL aliases expanding to `../..`, so they worked in argument position too
# (`vim ...`). That arrangement depended on auto_cd for the common case: bare
# `...` expanded to `../..` and auto_cd turned that into a cd.
#
# auto_cd is off now (see .zshrc — it silently cd'd into ~/.rc/tig whenever tig
# was not installed), and a global alias cannot cover both positions without it:
# a bare `...` would expand to `../..` and then be *executed*, which fails with
# "permission denied: ../..". zsh resolves a word containing a slash straight
# against the filesystem, so neither a function nor command_not_found_handler
# can intercept it.
#
# So these are ordinary aliases that cd. Trade-off, deliberate: they no longer
# expand as arguments — `vim ...` now passes `...` literally, where it used to
# mean `vim ../..`. Spell those out (`vim ../..`), or say `cd ...`.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

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
