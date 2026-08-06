# startup.zsh — shell startup functions, run once at login from .zshrc
#
# Most register a dim log line below the banner: banner_render walks
# BANNER_LOG_FUNCS top-to-bottom and each listed func calls banner_log "text"
# (and may do the startup work that produces it — banner_run demotes a noisy
# command's output into the logs, e.g. log_ssh's ssh-agent handling).
# Add a func below and list it in the registry; remove a line to silence it.
#
# banner_host_info is the exception: it prints instead of registering, because
# it feeds the first info line beside the mascot rather than the logs.

BANNER_LOG_FUNCS=(
    log_shell
    log_tmux
    log_ssh
)

# zsh version + startup time, e.g. "zsh 5.9 · 361 ms".
# _BANNER_T0 is stamped on .zshrc line 1; the timing is dropped if it's unset.
log_shell() {
    local seg="zsh $ZSH_VERSION"
    if [[ -n $_BANNER_T0 ]]; then
        local -i ms=$(( (EPOCHREALTIME - _BANNER_T0) * 1000 ))
        seg+=" · ${ms} ms"
    fi
    banner_log "$seg"
}

# host + session type, e.g. "isg-darwin · local" / "isg-darwin · ssh from 10.0.0.5"
# — who and where, so it belongs on the identity line next to the user name
# rather than buried in the logs. Printed, not registered: .zshrc assembles the
# info lines itself, before banner_render walks the log registry.
banner_host_info() {
    local where="local"
    if [[ -n $SSH_CONNECTION || -n $SSH_TTY ]]; then
        where="ssh from ${SSH_CONNECTION%% *}"
    fi
    print -r -- "${HOST%%.*} · ${where}"
}

# tmux, one laconic line — the whole server picture as slug:sessions, with the
# attached sessions named in brackets, e.g. "tmux · a:1 default:9(rc*) misc:4".
# A server with nothing attached carries no bracket at all, so the eye lands on
# the session actually holding a client.
# Every socket in $TMUX_TMPDIR/tmux-$UID is one server; a stale one answers
# nothing and is skipped, so only live servers are listed, socket order.
# list-sessions prints a client count per session — 0 means detached, and a
# session held by two windows scores two stars: "default:9(rc**)".
# Silent when tmux is absent or no server is alive.
log_tmux() {
    (( $+commands[tmux] )) || return 0
    local sock line mark
    local -a sessions attached servers
    for sock in ${TMUX_TMPDIR:-/tmp}/tmux-${UID}/*(=N); do
        # "<attached> <name>" per session — the count leads so a name
        # containing spaces still survives the ${line#* } split below.
        sessions=( ${(f)"$(command tmux -S $sock list-sessions \
            -F '#{session_attached} #{session_name}' 2>/dev/null)"} )
        (( ${#sessions} )) || continue
        attached=()
        for line in $sessions; do
            # #{session_attached} is a client COUNT, not a flag, so spend one
            # star per client: two windows on the same session read "rc**".
            local -i n=${line%% *}
            (( n )) && attached+=( "${line#* }${(l:n::*:)}" )
        done
        mark=""
        (( ${#attached} )) && mark="(${(j:,:)attached})"
        servers+=( "${sock:t}:${#sessions}${mark}" )
    done
    (( ${#servers} )) || return 0
    banner_log "tmux · ${(j: :)servers}"
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
