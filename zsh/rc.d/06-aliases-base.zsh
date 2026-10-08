# oh-my-zsh's ls/grep colour aliases. -G is BSD/Darwin; GNU ls wants --color,
# where -G means "hide group" instead — pick by OSTYPE rather than probing, so
# this costs no subprocess (oh-my-zsh ran `ls --color=tty` to decide).
if [[ $OSTYPE == darwin* || $OSTYPE == *bsd* ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=tty'
fi
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
alias history='fc -l 1'

# keep the whole history — the init block above defaults SAVEHIST to 10k,
# which trims the file (recovered Jun 2026 after a wipe; see .zsh_history.bak-*)
SAVEHIST=50000
