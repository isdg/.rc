# fzf-tab: Tab shows every completion list in fzf. Sourced by the first Tab,
# which saves ~6 ms of startup. It lists through the widget bound to Tab
# before it, so that is restored first: fzf's ** trigger, when loaded.
_brew_prefix="${HOMEBREW_PREFIX:-${commands[brew]:h:h}}"
for _ftb in "$_brew_prefix/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh" \
            "$HOME/.local/share/zsh/fzf-tab/fzf-tab.zsh"; do
    [[ -f $_ftb ]] || continue
    typeset -g _rc_fzf_tab=$_ftb
    fzf-tab-load() {
        local km prev=expand-or-complete
        (( $+widgets[fzf-completion] )) && prev=fzf-completion
        for km in emacs viins; do bindkey -M $km '^I' $prev; done
        source $_rc_fzf_tab && zle fzf-tab-complete
    }
    zle -N fzf-tab-load
    bindkey -M emacs '^I' fzf-tab-load
    bindkey -M viins '^I' fzf-tab-load
    zstyle ':completion:*' menu no
    break
done
unset _brew_prefix _ftb
