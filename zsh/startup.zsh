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

# The ssh origin recovered from utmp, computed at most once.
#
# sudo is the hard case for both info lines below. `Defaults env_reset` wipes
# SSH_CONNECTION *and* SSH_TTY, so a root shell on a remote box inherits
# nothing and naive code falls through to "local" — the one claim that is
# certainly false there. The environment cannot be trusted back into place
# either: those variables are plain strings, so `SSH_CONNECTION="..." sudo -s`
# would forge the line. utmp is the answer instead — sshd wrote the entry at
# login, sudo cannot touch it, and `who -m` reads the one for the tty on stdin.
# The parenthesised field is the origin; a local login has none, and a tmux
# pane has no utmp entry at all on darwin, so both yield "" and the callers
# fall back to saying nothing rather than guessing.
#
# The probe costs a fork and both banner_host_info and banner_net_info want the
# same answer, so it is memoised — one fork per login, not two. Callers gate it
# on SUDO_USER, which sudo sets itself: an ordinary interactive startup never
# reaches here and stays subprocess-free.
_banner_sudo_origin() {
    if (( ! ${+_banner_sudo_origin_done} )); then
        typeset -g _banner_sudo_origin_done=1 _banner_sudo_origin=
        local line=$(command who -m 2>/dev/null)
        [[ $line == *'('*')' ]] && typeset -g _banner_sudo_origin=${${line##*\(}%\)}
    fi
    print -r -- "$_banner_sudo_origin"
}

# host + session kind, e.g. "isg-darwin · local" / "isg-darwin · ssh"
# — who and what kind of session, so it belongs on the identity line next to
# the user name rather than buried in the logs. Printed, not registered:
# .zshrc assembles the info lines itself, before banner_render walks the log
# registry.
#
# The name is always THIS machine ($HOST), never the peer: on a box you sshed
# into it names the box you landed on. Deliberately address-free — the numbers
# live on the line below, so this one answers "who and what" and never makes
# you read an IP to find out you are simply at home.
#
# SUDO_USER names who made the jump and rides along on every branch. Under sudo
# on a local box the origin probe finds no parenthesis, so the line says only
# "isg-darwin · via isg" — no session kind, because utmp cannot prove one.
banner_host_info() {
    local where
    if [[ -n $SSH_CONNECTION || -n $SSH_TTY ]]; then
        where="ssh"
    elif [[ -n $SUDO_USER ]]; then
        [[ -n $(_banner_sudo_origin) ]] && where="ssh"
    else
        where="local"
    fi
    print -r -- "${HOST%%.*}${where:+ · $where}${SUDO_USER:+ · via $SUDO_USER}"
}

# the two addresses, e.g. "100.81.165.60 · ssh from 100.70.55.75" — this end of
# the connection first, then the peer, so the line reads inward-out: at which
# address, reached from where. Second info line, directly under the identity.
#
# Both come out of $SSH_CONNECTION, "<client-ip> <client-port> <server-ip>
# <server-port>": field 3 is this end of the socket, i.e. the address the
# client actually reached, which is the useful one on a multi-homed box. No
# ifconfig/ip subprocess at startup — sshd already knows.
#
# Prints nothing on a local login, and .zshrc then skips the line entirely:
# there is no peer to name, and this machine's own address would cost a fork to
# learn — too much for a number you did not ask for. Under sudo only the origin
# survives (utmp records where the login came from, not which local address it
# landed on), so the line degrades to "ssh from <origin>" rather than lying
# about this end.
banner_net_info() {
    local here there
    if [[ -n $SSH_CONNECTION ]]; then
        local -a conn=( ${=SSH_CONNECTION} )
        here=$conn[3] there=$conn[1]
    elif [[ -n $SUDO_USER ]]; then
        there=$(_banner_sudo_origin)
    fi
    [[ -z $here && -z $there ]] && return 0
    print -r -- "${here}${here:+${there:+ · }}${there:+ssh from $there}"
}

# tmux, one laconic line — the whole server picture as slug:sessions, with the
# attached sessions named in brackets, e.g. "tmux · a:1 *default:9(rc*) misc:4".
# A server with nothing attached carries no bracket at all, so the eye lands on
# the session actually holding a client.
# Every socket in $TMUX_TMPDIR/tmux-$UID is one server; a stale one answers
# nothing and is skipped, so only live servers are listed, socket order.
# list-sessions prints a client count per session — 0 means detached, and a
# session held by two windows scores two stars: "default:9(rc**)".
# A client attached over ssh spends a "#" instead, so "misc*#" is one local
# window plus one remote one and "work#" is a session nobody here is watching.
# The server this very shell sits in gets a leading star — "*default:10(rc*)"
# — so the picture says which of several servers you are actually inside.
# $TMUX is "<socket>,<pid>,<session>"; both sides go through :A because
# /tmp is a symlink on darwin and the glob and $TMUX spell it differently.
# Silent when tmux is absent or no server is alive.
#
# Remoteness is not a tmux fact: none of the #{client_*} formats expose the
# peer, so it comes from utmp the same way banner_host_info gets it — match
# #{client_tty} against `who`, whose parenthesised field is the origin. That
# costs one fork for `who` plus one list-clients per live server, so the whole
# lookup is skipped when `who` shows nobody logged in from elsewhere, which is
# every ordinary local login: one fork, and both the "#" and the per-host lines
# below stay quiet.
log_tmux() {
    (( $+commands[tmux] )) || return 0
    local sock line mark here self tty sess host
    local -a sessions attached servers
    # rsess is host -> sessions and spans every server, so a box attached to
    # sessions on two of them is named once; rcount is per server, since
    # session names only mean anything inside one.
    local -A origin rcount rsess
    [[ -n $TMUX ]] && here=${${TMUX%%,*}:A}
    # tty -> origin, remote logins only. Empty means nobody is on from
    # elsewhere, and every list-clients call below is then pointless.
    for line in ${(f)"$(command who 2>/dev/null)"}; do
        [[ $line == *'('*')' ]] || continue
        origin[${${=line}[2]}]=${${line##*\(}%\)}
    done
    for sock in ${TMUX_TMPDIR:-/tmp}/tmux-${UID}/*(=N); do
        # "<attached> <name>" per session — the count leads so a name
        # containing spaces still survives the ${line#* } split below.
        sessions=( ${(f)"$(command tmux -S $sock list-sessions \
            -F '#{session_attached} #{session_name}' 2>/dev/null)"} )
        (( ${#sessions} )) || continue
        rcount=()
        if (( ${#origin} )); then
            # tty leads here for the same reason the count leads above: a tty
            # never contains a space, a session name may.
            for line in ${(f)"$(command tmux -S $sock list-clients \
                -F '#{client_tty} #{client_session}' 2>/dev/null)"}; do
                tty=${line%% *} sess=${line#* }
                host=${origin[${tty:t}]}
                [[ -n $host ]] || continue
                (( rcount[$sess]++ ))
                # two windows from one box are two marks but one mention
                [[ ,${rsess[$host]}, == *,$sess,* ]] \
                    || rsess[$host]+="${rsess[$host]:+,}$sess"
            done
        fi
        attached=()
        for line in $sessions; do
            # #{session_attached} is a client COUNT, not a flag, so spend one
            # mark per client: two windows on the same session read "rc**".
            local -i n=${line%% *} r
            sess=${line#* }
            (( n )) || continue
            r=${rcount[$sess]:-0}
            # clamp: list-sessions and list-clients are two calls, so a client
            # that attached between them would otherwise overrun the count
            (( r > n )) && r=n
            attached+=( "${sess}${(l:n-r::*:)}${(l:r::#:)}" )
        done
        mark=""
        (( ${#attached} )) && mark="(${(j:,:)attached})"
        self=""
        [[ -n $here && ${sock:A} == $here ]] && self="*"
        servers+=( "${self}${sock:t}:${#sessions}${mark}" )
    done
    (( ${#servers} )) || return 0
    banner_log "tmux · ${(j: :)servers}"
    # One line per host, naming what the "#" above can only point at, and
    # nothing at all when every client is local. Host-first because a box you
    # sshed in from usually holds several sessions, so this collapses the
    # repetition the other pivot duplicates; one line each because the list
    # then grows downward instead of running off the right edge — five clients
    # on one line came to 92 columns. (ko) for a stable order: zsh does not
    # promise one for an associative array's keys.
    for host in ${(ko)rsess}; do
        banner_log "tmux · remote · ${rsess[$host]//,/, } ← $host"
    done
    return 0    # the loop above may run zero times; don't leak its status
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
