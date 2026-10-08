# _zsh_cached <name> <file>... -- <cmd>...
# Keeps cmd's stdout in a cache file, REPLY, rerunning cmd only when a <file>
# moves, changes mtime or appears; an empty <file> (unresolved binary) fails.
zmodload -F zsh/stat b:zstat
_zsh_cached() {
    local name=$1 key=
    local -a mtime
    shift
    while (( $# )) && [[ $1 != -- ]]; do
        [[ -n $1 ]] || return 1
        if zstat -A mtime +mtime -- $1 2>/dev/null; then
            key+="${1:A} $mtime[1];"
        else
            key+="$1 -;"
        fi
        shift
    done
    shift
    REPLY=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/$name
    [[ -r $REPLY.key && "$(<$REPLY.key)" == $key ]] && return 0
    [[ -d ${REPLY:h} ]] || mkdir -p ${REPLY:h}
    if "$@" >| $REPLY.$$ 2>/dev/null; then
        mv -f $REPLY.$$ $REPLY && print -r -- $key >| $REPLY.key
    else
        rm -f $REPLY.$$
        return 1
    fi
}
