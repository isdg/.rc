# Whatever belongs to this box rather than to the config — SSH_KEYS above all.
# Sourced exactly here: after 21-startup.zsh, whose `typeset -ga SSH_KEYS=()` it
# has to win over, and before banner_render, which is what runs log_ssh.
#
# In $HOME rather than on a setup/<machine> branch because ~/.zshrc is a symlink
# into the working tree, so a branch-held value follows HEAD: a shell opened
# while the repo sat on main got SSH_KEYS empty, and log_ssh — whose empty-list
# guard only fires when no agent is reachable — then printed "ssh-agent · 1 key"
# and added nothing, silently. $HOME is not a checkout, so this survives.
# zsh/zshrc.local.example is the template to copy out.
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local
