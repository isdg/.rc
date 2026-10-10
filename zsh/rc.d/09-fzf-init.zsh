# `fzf --zsh` is cached; ~/.fzf.zsh (which runs it, after fixing PATH) is the
# fallback for an fzf off PATH or too old for --zsh.
if _zsh_cached fzf "$commands[fzf]" -- fzf --zsh; then
    source $REPLY
elif [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
else
    # No clone: fall back to the snippets a distro package installs, so ^R and
    # ^T still work on a box where only apt/pacman fzf is present.
    for _fzf_dir in /usr/share/doc/fzf/examples /usr/share/fzf; do
        [[ -f $_fzf_dir/key-bindings.zsh ]] && source $_fzf_dir/key-bindings.zsh
        [[ -f $_fzf_dir/completion.zsh ]] && source $_fzf_dir/completion.zsh
    done
    unset _fzf_dir
fi
