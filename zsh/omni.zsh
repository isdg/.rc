# omni — snapshot the pane shell's exported environment per tmux pane.
#
# omni's pane-capture (prefix j/J/P in ~/omni) opens the captured scrollback in
# a fresh tmux window. tmux runs that binding with the *server's* environment,
# and on macOS `ps -E` can't read vars exported after the shell started, so a
# venv / direnv / exported project vars activated interactively would be lost.
# To preserve them, the shell records its own exported environment on every
# prompt; pane-capture reads it back and re-applies it (minus a denylist of
# pane/terminal-specific vars) to the new window via `new-window -e`.
#
# Written per pane ($TMUX_PANE, e.g. %3 -> file "3"), NUL-delimited so values
# with spaces/newlines round-trip, and overwritten every prompt so a reused
# pane id self-corrects. May contain secrets (exported API keys, etc.), so the
# directory is 700. Keep the path in sync with pane-capture.sh in ~/omni.
[[ -n $TMUX ]] || return 0

: ${OMNI_ENV_DIR:=${XDG_CACHE_HOME:-$HOME/.cache}/omni/env}

_omni_record_env() {
    [[ -n $TMUX_PANE ]] || return 0
    [[ -d $OMNI_ENV_DIR ]] ||
        { mkdir -p "$OMNI_ENV_DIR" && chmod 700 "$OMNI_ENV_DIR"; } 2>/dev/null ||
        return 0
    local f="$OMNI_ENV_DIR/${TMUX_PANE#%}" k
    {
        # `typeset +xg` lists the names of exported params (the process
        # environment). Dump each NAME=VALUE NUL-delimited so values with
        # spaces/newlines round-trip. ${(P)k} dereferences the name.
        for k in ${(f)"$(typeset +xg)"}; do
            printf '%s=%s\0' "$k" "${(P)k}"
        done
    } >| "$f.tmp" 2>/dev/null && mv -f "$f.tmp" "$f" 2>/dev/null
    return 0
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _omni_record_env
