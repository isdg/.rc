# startup banner: mascot · status lines · quiet logs
#
#          ▼ q₀        isg · zsh
#   ┄┬─┬─┬─┬─┬─┬┄      Wed 11 Jun 2026 · 20:42
#   ┄┤0│1│1│0│1├┄      zsh 5.9 · 77 ms
#   ┄┴─┴─┴─┴─┴─┴┄
#   δ(q₀,0)=⟨B,1,R⟩
#
#     · ssh-agent started · pid 724
#     · Identity added: /Users/isg/.ssh/delos-new (...)
#
# Interface
#   banner_info "text"        add a status line, shown right of the mascot
#                             (prompt escapes allowed: %B %F{..} %~ %D{..} ...)
#   BANNER_LOG_FUNCS=( ... )  registry of log funcs, run in order by render —
#                             each func holds one log message (below)
#   banner_log  "text"        add a dim log line, shown below the banner
#   banner_run  cmd ...       run a noisy command, demoting its output to logs
#   banner_render             consume the registry and draw — call once, last
#
# Config
#   BANNER_MODE=mode           full (default) · nomascot · nologs · off.
#                              The log funcs run in every mode, off too:
#                              their side effects (ssh-agent) still matter.
#   BANNER_ACCENT=color        mascot color (default: 244, a mid grey that
#                              holds up on both the dark and light background).
#                              Any %F{..} value: a base name, or 0-255. Note
#                              zsh has no `grey`/`gray` name — both fall back
#                              to the default foreground — so greys need a
#                              number.
#   BANNER_INFO_OFFSET=n       rows the info lines start below the mascot's
#                              top (default 1)
# ----------------------------------------------------------------------------

typeset -ga BANNER_LOG_FUNCS=()
typeset -ga _banner_info_lines=()
typeset -ga _banner_log_lines=()

banner_info() { _banner_info_lines+=("$*") }
banner_log()  { _banner_log_lines+=("$*") }

banner_run() {
    local _out _line
    _out="$("$@" 2>&1)"
    for _line in ${(f)_out}; do
        banner_log "$_line"
    done
}

# ── mascot: turing machine tape ──
# Lines may be shorter than _banner_mascot_width (they get padded) but
# never longer (they get truncated). Swap art freely.
#
# A Turing machine is the 7-tuple M = ⟨Q,Γ,b,Σ,δ,q₀,F⟩ (Hopcroft &
# Ullman) — here instantiated as the 3-state busy beaver:
#
#   Q    set of states                   {A, B, C, HALT}
#   Γ    tape alphabet                   {0, 1}
#   b    blank symbol,  b ∈ Γ            0
#   Σ    input symbols, Σ ⊆ Γ∖{b}        {1}
#   δ    transition function             (Q∖F) × Γ ⇀ Q × Γ × {L,R}
#   q₀   initial state, q₀ ∈ Q           A
#   F    final states,  F ⊆ Q            {HALT}
#
# δ takes a pair (current state, symbol under the head) and returns a
# triple (next state, symbol to write, head move):
#
#   δ(q₀, 0) = ⟨B, 1, R⟩
#      │   │     │  │  │
#      │   │     │  │  └─ then move the head one cell Right
#      │   │     │  └──── write 1 over the 0
#      │   │     └─────── switch to state B
#      │   └───────────── ...while reading symbol 0
#      └───────────────── in state q₀ (= state A, the initial state)...
#
# The mascot is that machine at step zero:
#
#          ▼ q₀          head in the initial state q₀ (=A), reading 0
#   ┄┬─┬─┬─┬─┬─┬┄
#   ┄┤0│1│1│0│1├┄        the tape; ┄ = blanks (b=0) to infinity
#   ┄┴─┴─┴─┴─┴─┴┄
#   δ(q₀,0)=⟨B,1,R⟩      the next move, computed but not yet taken
#
# The machine looks up δ for (q₀, 0) — the top-left entry of the busy
# beaver state table. One step later the tape would read 0│1│1│1│1 and
# the head would sit one cell to the right, labeled ▼ q_B. So the
# banner is a freeze-frame of the machine mid-thought.
#
# Why it ever stops: δ is partial — when no rule exists for the current
# (state, symbol) pair, the machine halts. The busy beaver reaches the
# explicit HALT ∈ F state after 14 steps, having written six 1s — the
# most a 3-state machine can do and still terminate. A fitting mascot
# for a shell: maximum output, guaranteed to terminate.
typeset -ga _banner_mascot=(
    '       ▼ q₀'
    '┄┬─┬─┬─┬─┬─┬┄'
    '┄┤0│1│1│0│1├┄'
    '┄┴─┴─┴─┴─┴─┴┄'
    'δ(q₀,0)=⟨B,1,R⟩'
)
typeset -g _banner_mascot_width=16

# Alternative: signed with the formal 7-tuple instead of a transition
#   '       ▼ q₀'
#   '┄┬─┬─┬─┬─┬─┬┄'
#   '┄┤0│1│1│0│1├┄'
#   '┄┴─┴─┴─┴─┴─┴┄'
#   '⟨Q,Γ,b,Σ,δ,q₀,F⟩'
#
# Alternative: tape spells the owner, head parked on `i`
#   '       ▼'
#   '┄┬─┬─┬─┬─┬─┬┄'
#   '┄┤0│1│i│s│g├┄'
#   '┄┴─┴─┴─┴─┴─┴┄'
#
# Alternative: chunky block tape (delos style)
#   '      ▗█▖'
#   '▄▄▄▄▄▄▟█▙▄▄▄▄'
#   '▌0▐1▐0█1█▌1▐0'
#   '▀▀▀▀▀▀▀▀▀▀▀▀▀'

# ── toy: the beaver lives through the week ──
# Each day the machine is ⌊14·d/6⌋ steps into its run (d = 0 on Monday).
# The static array above is Monday's step zero (q₀ = qA); this
# overwrites it with today's frame: simulated tape window around the
# head, current state, and the pending transition (HALT → H in the
# triple). The week, frame by frame (window = head ± 2 cells):
#
#   Mon   0  ┄┤0│0│0│0│0├┄  δ(qA,0)=⟨B,1,R⟩  reborn on a blank tape;
#                                            plants the 1st of six 1s
#   Tue   2  ┄┤0│0│1│1│0├┄  δ(qA,1)=⟨C,1,L⟩  wrote two 1s, bounced
#                                            back; turns left
#   Wed   4  ┄┤0│0│0│1│1├┄  δ(qB,0)=⟨A,1,L⟩  marching left, laying 1s
#                                            at the frontier
#   Thu   7  ┄┤1│1│1│1│1├┄  δ(qB,1)=⟨B,1,R⟩  left edge sealed; begins
#                                            the long right sweep
#   Fri   9  ┄┤1│1│1│0│0├┄  δ(qB,1)=⟨B,1,R⟩  B's self-loop rides over
#                                            its own 1s, head → right
#   Sat  11  ┄┤1│1│1│1│0├┄  δ(qA,1)=⟨C,1,L⟩  6th and last 1 written;
#                                            turns back inward
#   Sun  14  ┄┤1│1│1│1│0├┄  δ(HALT,·) = ∅ ∎  qC read a 1 → HALT ∈ F;
#                                            six 1s, machine rests
#
# Stages of the underlying 13-transition run: plant two 1s and bounce
# (1-2) → march left extending the block (3-5) → turn at the left edge
# (6) → sweep right over the 1s via δ(B,1)=⟨B,1,R⟩ (7-10) → seal the
# right edge with the 6th 1 (11) → walk in and hit δ(C,1)=⟨HALT,1,R⟩
# (12-13). Monday it is reborn at step zero.
__isg::beaver_mascot() {
    local -i steps=$1 head=0 i
    local state=A sym label move
    local -a rule cells
    local -A tape
    local -A delta=(
        A0 '1 R B'   A1 '1 L C'
        B0 '1 L A'   B1 '1 R B'
        C0 '1 L B'   C1 '1 R HALT'
    )
    for (( i = 0; i < steps; i++ )); do
        sym=${tape[$head]:-0}
        rule=( ${=delta[${state}${sym}]} )
        (( ${#rule} )) || break
        tape[$head]=$rule[1]
        if [[ $rule[2] == R ]]; then (( head++ )); else (( head-- )); fi
        state=$rule[3]
    done
    for i in {-2..2}; do
        cells+=( "${tape[$(( head + i ))]:-0}" )
    done
    sym=${tape[$head]:-0}
    rule=( ${=delta[${state}${sym}]} )
    label="q$state"; [[ $state == HALT ]] && label='HALT'
    if (( ${#rule} )); then
        move="δ($label,$sym)=⟨${rule[3]/HALT/H},$rule[1],$rule[2]⟩"
    else
        move="δ($label,·) = ∅ ∎"
    fi
    _banner_mascot=(
        "       ▼ $label"
        '┄┬─┬─┬─┬─┬─┬┄'
        "┄┤$cells[1]│$cells[2]│$cells[3]│$cells[4]│$cells[5]├┄"
        '┄┴─┴─┴─┴─┴─┴┄'
        "$move"
    )
}

if zmodload zsh/datetime 2>/dev/null; then
    strftime -s _isg_dow '%u' $EPOCHSECONDS   # 1 = Monday .. 7 = Sunday
    __isg::beaver_mascot $(( 14 * (_isg_dow - 1) / 6 ))
    unset _isg_dow
fi

banner_render() {
    local -i i rows off=${BANNER_INFO_OFFSET:-1}
    local fn mascot info line mode=${BANNER_MODE:-full}
    {
        # consume the log registry — funcs run in the current shell, so
        # exports they make (e.g. SSH_AUTH_SOCK) persist in the session
        for fn in "${BANNER_LOG_FUNCS[@]}"; do
            (( $+functions[$fn] )) && $fn
        done
        [[ $mode == off ]] && return 0
        print
        if [[ $mode == nomascot ]]; then
            for info in "${_banner_info_lines[@]}"; do
                print -P -- "    › ${info}"
            done
        else
            rows=$(( ${#_banner_mascot} > ${#_banner_info_lines} + off \
                     ? ${#_banner_mascot} : ${#_banner_info_lines} + off ))
            for (( i = 1; i <= rows; i++ )); do
                mascot="${_banner_mascot[i]:-}"
                info=""
                (( i > off )) && info="${_banner_info_lines[i - off]:-}"
                mascot=${(r:${_banner_mascot_width}:)mascot}
                print -P -- \
                    "  %F{${BANNER_ACCENT:-244}}${mascot}%f   ${info}"
            done
        fi
        if [[ $mode != nologs ]] && (( ${#_banner_log_lines} )); then
            print
            # no colour of their own: the logs take the default foreground,
            # the same as the info lines beside the mascot, in both themes
            for line in "${_banner_log_lines[@]}"; do
                print -P -- "    · ${line//\%/%%}"
            done
        fi
        print
    } always {
        # consumed — a re-source/re-render starts clean
        _banner_info_lines=() _banner_log_lines=()
    }
}

# ── log registry ──
# Most register a dim log line below the banner: banner_render walks
# BANNER_LOG_FUNCS top-to-bottom and each listed func calls banner_log "text"
# (and may do the startup work that produces it — banner_run demotes a noisy
# command's whole output into the logs when a line of its own won't do).
# Add a func below and list it in the registry; remove a line to silence it.
#
# banner_host_info and banner_net_info are the exceptions: they print instead
# of registering, because they feed the info lines beside the mascot rather
# than the logs. info_shell feeds them too, but registers: the timing must be
# read at render time, after ~/.zshrc.local.

BANNER_LOG_FUNCS=(
    info_shell
    log_tmux
    log_ssh
)

# zsh version + startup time, e.g. "zsh 5.9 · 361 ms", as the last info line.
# _BANNER_T0 is stamped on .zshrc line 1; the timing is dropped if it's unset.
info_shell() {
    local seg="zsh $ZSH_VERSION"
    if [[ -n $_BANNER_T0 ]]; then
        local -i ms=$(( (EPOCHREALTIME - _BANNER_T0) * 1000 ))
        seg+=" · ${ms} ms"
    fi
    banner_info "$seg"
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

# The peer's name, into REPLY: the one its zsh sent (LC_ISG_FROM, kept as
# ISG_SSH_FROM by .zshenv) unless $2 is 0, else Tailscale's for a tailnet
# address. No DNS: a slow resolver would stall the login. 1 when unnamed.
_banner_peer_name() {
    local -a names
    REPLY=
    if [[ $2 != 0 && -n $ISG_SSH_FROM ]]; then
        REPLY=$ISG_SSH_FROM
        return 0
    fi
    [[ $1 == (100.<64-127>.<->.<->|fd7a:115c:a1e0:*) ]] || return 1
    (( $+commands[tailscale] )) || return 1
    # The first Name: is the machine's (the second is the user's).
    names=( ${(M)${(f)"$(command tailscale whois $1 2>/dev/null)"}:#*Name:*} )
    REPLY=${${${names[1]#*Name:}// /}%%.*}
    [[ -n $REPLY ]]
}

# host + session kind, e.g. "isg-darwin · local" / "isg-darwin · ssh from
# isg-darwin-sigma"
# — who and what kind of session, so it belongs on the identity line next to
# the user name rather than buried in the logs. Printed, not registered:
# .zshrc assembles the info lines itself, before banner_render walks the log
# registry.
#
# The leading name is always THIS machine ($HOST): on a box you sshed into it
# names the box you landed on. The peer follows "ssh from" only when
# _banner_peer_name knows its name. Deliberately address-free — the numbers
# live on the line below, so this one answers "who and what" and never makes
# you read an IP to find out you are simply at home.
#
# SUDO_USER names who made the jump and rides along on every branch. Under sudo
# on a local box the origin probe finds no parenthesis, so the line says only
# "isg-darwin · via isg" — no session kind, because utmp cannot prove one.
# Under sudo only Tailscale names the peer: sudo -E would carry a forged
# ISG_SSH_FROM through.
banner_host_info() {
    local where origin REPLY
    if [[ -n $SSH_CONNECTION || -n $SSH_TTY ]]; then
        where="ssh"
        _banner_peer_name "${${=SSH_CONNECTION}[1]}" && where+=" from $REPLY"
    elif [[ -n $SUDO_USER ]]; then
        origin=$(_banner_sudo_origin)
        if [[ -n $origin ]]; then
            where="ssh"
            _banner_peer_name $origin 0 && where+=" from $REPLY"
        fi
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

# Keys log_ssh keeps in the agent, as paths to the private halves. Empty here
# on purpose: which key a machine holds is a property of that machine, not of
# this config, so ~/.zshrc.local sets it —
#
#     SSH_KEYS=( ~/.ssh/delos-new )
#
# Not a setup/<machine> branch: ~/.zshrc is a symlink into the working tree, so
# a branch-held list empties itself the moment HEAD moves elsewhere.
#
# With the list empty log_ssh reports the agent and stops there — no key is
# touched and no agent is started — so it is safe to register everywhere.
typeset -ga SSH_KEYS=()

# ssh-agent: reuse a reachable agent, add only the keys it is missing —
# was a noisy "Agent pid" / "Identity added" popping on every shell.
#
# One `ssh-add -l` answers both questions asked of the agent: exit 2 means none
# is reachable, and the output is the fingerprint list every key below is
# checked against. So the common case — agent up, everything already loaded —
# costs one fork plus one ssh-keygen per configured key.
#
# The agent line prints unconditionally, keys or none: whether an agent is even
# there is worth knowing on a box you just sshed into, and it is the line that
# explains a later "Permission denied (publickey)".
#
# ssh-add is run with askpass forced and pointed at a binary that fails, which
# is what keeps this safe to register everywhere: on an encrypted key an
# unguarded ssh-add sits on "Enter passphrase for …" and wedges the shell
# before the prompt ever appears — verified under a pty, it waits forever.
# Forced askpass makes it fail instead, and one `ssh-keygen -y -P ""` then
# separates "encrypted" from a real error so the line can say which. Loading an
# encrypted key stays a deliberate act you do by hand.
log_ssh() {
    local key name have out line agent note="" fp type tag
    local -i st n
    have=$(command ssh-add -l 2>/dev/null); st=$?
    if (( st == 2 )); then              # no agent reachable
        # Starting one is only worth a daemon when there is a key to put in it.
        # This function runs at every login on every box, and nothing ever
        # reaps an agent, so an unconditional start strands one per shell that
        # did not inherit a socket. With no keys configured there is nothing to
        # hold, so say what is true and start nothing.
        (( ${#SSH_KEYS} )) || { banner_log "ssh-agent · not running"; return 0 }
        eval "$(command ssh-agent -s)" >/dev/null 2>&1
        have=$(command ssh-add -l 2>/dev/null); st=$?
        (( st == 2 )) && { banner_log "ssh-agent · unreachable"; return 0 }
        # a flag, not $SSH_AGENT_PID: that variable is often already exported
        # by an agent started long ago, and a reused agent must not claim it
        # has just been started
        note=" · started · pid $SSH_AGENT_PID"
    fi
    if (( st == 0 )); then
        local -a fps=( ${(f)have} ); n=${#fps}
        agent="$n key"; (( n == 1 )) || agent+="s"
    else                                # exit 1 — agent is up but holds nothing
        agent="no keys"
    fi
    banner_log "ssh-agent$note · $agent"

    for key in $SSH_KEYS; do
        name=${key:t}
        [[ -r $key ]] || { banner_log "ssh · $name · no key at ${key/#$HOME/~}"; continue }
        # "256 SHA256:x2/Eb39… comment (ED25519)" — bits, fingerprint and type
        # from the one call, so naming the key costs nothing extra. The
        # fingerprint is the only half that distinguishes these: every key here
        # carries the same comment.
        local -a id=( ${(z)"$(command ssh-keygen -lf $key.pub 2>/dev/null)"} )
        fp=${id[2]} type=${${id[-1]#\(}%\)}
        # separator folded in, so a key whose .pub is missing reads
        # "ssh · name · added" rather than growing an empty field
        tag="${(L)type}${fp:+ ${fp[1,14]}}"
        tag=${tag:+ · $tag}
        if [[ -n $fp && $have == *$fp* ]]; then
            banner_log "ssh · $name$tag · loaded"
        elif out=$(SSH_ASKPASS_REQUIRE=force SSH_ASKPASS=/usr/bin/false DISPLAY= \
                   command ssh-add $key 2>&1); then
            banner_log "ssh · $name$tag · added"
        elif ! command ssh-keygen -y -P "" -f $key >/dev/null 2>&1; then
            banner_log "ssh · $name$tag · needs passphrase"
        else
            banner_log "ssh · $name$tag · ssh-add failed"
            for line in ${(f)out}; do banner_log "ssh · $name · $line"; done
        fi
    done
    return 0
}

# ── info lines, right of the mascot ──
# %n = the real user, not a hardcoded name: a root shell sourcing this config
# (sudo -E, su -m) says "root", so the banner can't claim to be isg while the
# shell can write anywhere.
banner_info "%B%n%b · $(banner_host_info)"
# addresses go on their own line under the identity, and only when there are
# any — a local login has no peer to name, so the banner stays three lines
_banner_net=$(banner_net_info)
[[ -n $_banner_net ]] && banner_info "$_banner_net"
unset _banner_net
banner_info "%D{%a %d %b %Y · %H:%M}"
