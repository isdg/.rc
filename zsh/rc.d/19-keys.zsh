# Up/Down search history by the prefix already typed — the one oh-my-zsh binding
# that is genuinely missed. Must come after 17-vimode.zsh: its `bindkey -v`
# re-aliases the main keymap and discards anything bound before it, so bind these
# in viins and vicmd explicitly.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
for _km in viins vicmd; do
    bindkey -M $_km '^[[A' up-line-or-beginning-search
    bindkey -M $_km '^[OA' up-line-or-beginning-search
    bindkey -M $_km '^[[B' down-line-or-beginning-search
    bindkey -M $_km '^[OB' down-line-or-beginning-search
done
unset _km

# Shift-Tab steps back through the completion menu (cd <Tab>, then Shift-Tab to
# go back one). The second oh-my-zsh binding worth keeping: its key-bindings.zsh
# bound terminfo[kcbt] to reverse-menu-complete in viins and vicmd, and dropping
# the framework took that with it, leaving Shift-Tab undefined while `menu
# select` still put a menu on screen with no way to walk it backwards.
#
# The literal escape rather than terminfo[kcbt], to match the block above and to
# keep zsh/terminfo out of a startup path that is measured; ^[[Z is what xterm,
# tmux and Ghostty all send. Bound in the main keymaps, not menuselect: a key
# that menuselect does not bind leaves the menu and is then processed normally,
# so this one binding serves both the open menu and plain cycling.
for _km in viins vicmd; do
    bindkey -M $_km '^[[Z' reverse-menu-complete
done
unset _km
