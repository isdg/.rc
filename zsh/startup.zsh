# startup.zsh — shell startup functions, run once at login from .zshrc
#
# Most register a dim log line below the banner: banner_render walks
# BANNER_LOG_FUNCS top-to-bottom and each listed func calls banner_log "text"
# (and may do the startup work that produces it — banner_run demotes a noisy
# command's output into the logs, e.g. log_ssh's ssh-agent handling).
# Add a func below and list it in the registry; remove a line to silence it.

BANNER_LOG_FUNCS=(
    log_shell
    log_host
    log_ssh
)

# zsh version + startup time, e.g. "zsh 5.9 · 361 ms".
# _BANNER_T0 is stamped on .zshrc line 1; the timing is dropped if it's unset.
log_shell() {
    local seg="v$ZSH_VERSION"
    if [[ -n $_BANNER_T0 ]]; then
        local -i ms=$(( (EPOCHREALTIME - _BANNER_T0) * 1000 ))
        seg+=" · ${ms} ms"
    fi
    banner_log "$seg"
}

# host + session type, e.g. "isg-darwin · local" / "isg-darwin · ssh from 10.0.0.5"
log_host() {
    local where="local"
    if [[ -n $SSH_CONNECTION || -n $SSH_TTY ]]; then
        where="ssh from ${SSH_CONNECTION%% *}"
    fi
    banner_log "${HOST%%.*} · ${where}"
}

# tmux, one minimal line — inside: current session · clients · detached;
# outside: counts only, silent when the server is idle or absent
log_tmux() {
    (( $+commands[tmux] )) || return 0
    local -a detached clients seg
    detached=( ${(f)"$(command tmux list-sessions \
        -F '#{?session_attached,,#{session_name}}' 2>/dev/null)"} )
    clients=( ${(f)"$(command tmux list-clients -F x 2>/dev/null)"} )
    [[ -n $TMUX ]] && seg+=("$(command tmux display-message -p '#S' 2>/dev/null)")
    local cs="clients"; (( ${#clients} == 1 )) && cs="client"
    (( ${#clients} ))  && seg+=("${#clients} $cs")
    (( ${#detached} )) && seg+=("${#detached} detached")
    (( ${#seg} )) || return 0
    banner_log "tmux · ${(j: · :)seg}"
}

# ssh-agent: reuse a reachable agent, add the key only if missing —
# was a noisy "Agent pid" / "Identity added" popping on every shell
log_ssh() {
    local key=~/.ssh/delos-new fp
    ssh-add -l &>/dev/null
    if (( $? == 2 )); then              # no agent reachable → start one
        eval "$(ssh-agent -s)" >/dev/null
        banner_log "ssh-agent started · pid $SSH_AGENT_PID"
    fi
    [[ -f $key.pub ]] && fp=$(ssh-keygen -lf $key.pub 2>/dev/null | awk '{print $2}')
    if [[ -n $fp ]] && ssh-add -l 2>/dev/null | command grep -qF "$fp"; then
        banner_log "ssh · delos-new ✓"
    else
        banner_run ssh-add $key
    fi
}
