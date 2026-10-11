# OSC 133 shell marks, which tmux 3.8 turns into pane-command-finished and
# friends (tmux/rc.d/12-alerts.conf). Outside tmux, Ghostty's own shell
# integration already sends them.
[[ -n $TMUX ]] || return 0

typeset -gi _osc133_running=0

_osc133_preexec() {
    _osc133_running=1
    printf '\e]133;C\a'
}

_osc133_precmd() {
    local st=$?
    (( _osc133_running )) && printf '\e]133;D;%d\a' $st
    _osc133_running=0
    printf '\e]133;A\a'
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _osc133_preexec
add-zsh-hook precmd _osc133_precmd
