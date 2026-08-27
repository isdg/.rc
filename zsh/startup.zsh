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

# host + session type, e.g. "isg-darwin · local"
# / "isg-darwin · 10.0.0.4 · ssh from 10.0.0.5"
# — who and where, so it belongs on the identity line next to the user name
# rather than buried in the logs. Printed, not registered: .zshrc assembles the
# info lines itself, before banner_render walks the log registry.
#
# The name is always THIS machine ($HOST), never the peer: on a box you sshed
# into it names the box you landed on. Under ssh the address of this machine
# goes between the two, so the line reads inward-out — which host, at which
# address, reached from where.
#
# Both addresses come out of $SSH_CONNECTION, "<client-ip> <client-port>
# <server-ip> <server-port>": field 3 is this end of the socket, i.e. the
# address the client actually reached, which is the useful one on a
# multi-homed box. No ifconfig/ip subprocess at startup — sshd already knows.
#
# sudo is the hard case. `Defaults env_reset` wipes SSH_CONNECTION *and*
# SSH_TTY, so a root shell on a remote box inherits nothing and the old code
# fell through to "local" — the one claim that is certainly false there. The
# environment cannot be trusted back into place either: those variables are
# plain strings, so `SSH_CONNECTION="..." sudo -s` would forge the line. utmp
# is the answer instead — sshd wrote the entry at login, sudo cannot touch it,
# and `who -m` reads the one for the tty on stdin. The parenthesised field is
# the origin; a local login has none, and a tmux pane has no utmp entry at all
# on darwin, so both fall back to saying nothing rather than guessing.
#
# The probe costs a fork, so it is gated on SUDO_USER, which sudo sets itself:
# an ordinary interactive startup never reaches it and stays subprocess-free.
# SUDO_USER also names who made the jump, and that suffix rides along on every
# branch — under `sudo -E` the ssh vars survive and both halves are known.
banner_host_info() {
    local where line
    if [[ -n $SSH_CONNECTION || -n $SSH_TTY ]]; then
        local -a conn=( ${=SSH_CONNECTION} )
        where="ssh${conn[1]:+ from $conn[1]}"
        [[ -n $conn[3] ]] && where="$conn[3] · $where"
    elif [[ -n $SUDO_USER ]]; then
        line=$(command who -m 2>/dev/null)
        [[ $line == *'('*')' ]] && where="ssh from ${${line##*\(}%\)}"
    else
        where="local"
    fi
    print -r -- "${HOST%%.*}${where:+ · $where}${SUDO_USER:+ · via $SUDO_USER}"
}

# tmux, one laconic line — the whole server picture as slug:sessions, with the
# attached sessions named in brackets, e.g. "tmux · a:1 *default:9(rc*) misc:4".
# A server with nothing attached carries no bracket at all, so the eye lands on
# the session actually holding a client.
# Every socket in $TMUX_TMPDIR/tmux-$UID is one server; a stale one answers
# nothing and is skipped, so only live servers are listed, socket order.
# list-sessions prints a client count per session — 0 means detached, and a
# session held by two windows scores two stars: "default:9(rc**)".
# The server this very shell sits in gets a leading star — "*default:10(rc*)"
# — so the picture says which of several servers you are actually inside.
# $TMUX is "<socket>,<pid>,<session>"; both sides go through :A because
# /tmp is a symlink on darwin and the glob and $TMUX spell it differently.
# Silent when tmux is absent or no server is alive.
log_tmux() {
    (( $+commands[tmux] )) || return 0
    local sock line mark here self
    local -a sessions attached servers
    [[ -n $TMUX ]] && here=${${TMUX%%,*}:A}
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
        self=""
        [[ -n $here && ${sock:A} == $here ]] && self="*"
        servers+=( "${self}${sock:t}:${#sessions}${mark}" )
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
