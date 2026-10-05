# --- vi mode on the command line ---
bindkey -v
# KEYTIMEOUT is in 1/100s. =10 → 100ms: snappy ESC (default 40=400ms feels
# laggy) while still giving multi-byte escape sequences time to assemble. At
# =1 (10ms) the trailing bytes of the bracketed-paste markers \e[200~/\e[201~
# and arrow keys race the timeout across Ghostty→tmux→zsh; a lost race makes
# ZLE read the lone ESC as "enter vicmd", so part of a paste is interpreted as
# vi normal-mode commands and a character gets eaten (intermittent dropped
# letter on paste).
export KEYTIMEOUT=10

# Backspace deletes anything on the line, not just what this insert session typed.
# zsh binds viins ^? to vi-backward-delete-char, which "won't delete past the point
# where insert mode was last entered" — and a lost paste race plants that mid-paste.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

# In normal mode: v or n opens $EDITOR on the current command line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'n' edit-command-line

function _clip_copy() {
   printf "%s" "$1" | pbcopy 2>/dev/null \
      || printf "%s" "$1" | xclip -selection clipboard 2>/dev/null
}

# Plain y is zsh's own yank, as in nvim; the clipboard is <Space>y in visual mode
# (the `visual` keymap, nvim's x mode), so it never collides with <Space>y*.
function vi-yank-clipboard() {
   zle vi-yank
   _clip_copy "$CUTBUFFER"
}
zle -N vi-yank-clipboard
bindkey -M visual ' y' vi-yank-clipboard

# In normal mode: <Space>p puts the system clipboard after the cursor, like vim's
# "+p. CUTBUFFER is restored so plain p still puts the last yank.
function vi-put-clipboard() {
   local saved="$CUTBUFFER"
   CUTBUFFER="$(pbpaste 2>/dev/null || xclip -selection clipboard -o 2>/dev/null)"
   zle vi-put-after
   CUTBUFFER="$saved"
}
zle -N vi-put-clipboard
bindkey -M vicmd ' p' vi-put-clipboard
# Lone Space (vi-forward-char, same as l) unbound so Space acts as a pure leader:
# ZLE waits for the next key untimed instead of cutting off at KEYTIMEOUT.
bindkey -M vicmd -r ' '

# The rest of the <Space> leader, on nvim's letters. No leader key is both bound
# and a prefix (hence yy, not y), so every one of them waits untimed.
function vi-yank-line-clipboard() { _clip_copy "$BUFFER"; zle -M "copied command line" }
function vi-yank-cwd-clipboard() { _clip_copy "$PWD"; zle -M "copied $PWD" }
function vi-yank-cwd-name-clipboard() { _clip_copy "${PWD:t}"; zle -M "copied ${PWD:t}" }
# Relative to the repo root; outside a repo, ~-relative.
function vi-yank-cwd-rel-clipboard() {
   local rel
   if rel=$(git rev-parse --show-prefix 2>/dev/null); then
      rel=${${rel%/}:-.}
   else
      rel=${(D)PWD}
   fi
   _clip_copy "$rel"
   zle -M "copied $rel"
}
zle -N vi-yank-line-clipboard
zle -N vi-yank-cwd-clipboard
zle -N vi-yank-cwd-name-clipboard
zle -N vi-yank-cwd-rel-clipboard

bindkey -M vicmd ' yy' vi-yank-line-clipboard
bindkey -M vicmd ' yf' vi-yank-cwd-name-clipboard
bindkey -M vicmd ' yp' vi-yank-cwd-clipboard
bindkey -M vicmd ' yP' vi-yank-cwd-rel-clipboard
bindkey -M vicmd ' x'  kill-whole-line
bindkey -M vicmd ' a'  fzf-rg-live-widget
bindkey -M vicmd ' A'  fzf-rg-filter-widget
bindkey -M vicmd ' gd' fzf-git-changed-widget
bindkey -M vicmd ' gm' fzf-git-commit-widget
bindkey -M vicmd ' b'  fzf-git-branch-widget
bindkey -M vicmd ' J'  fzf-dirstack-widget
# fzf's own widgets, from its key-bindings.zsh (loaded before this file).
(( $+widgets[fzf-file-widget] ))    && bindkey -M vicmd ' f' fzf-file-after-widget
(( $+widgets[fzf-history-widget] )) && bindkey -M vicmd ' ;' fzf-history-widget
(( $+widgets[fzf-history-widget] )) && bindkey -M vicmd ' r' fzf-history-widget

# Unbind K (default = run-help → opens man page; sometimes leaves ZLE in a
# broken redraw state on return)
bindkey -M vicmd -r 'K'

# Cursor shape per mode + mode-aware isg prompt caret
# user:  » in normal, › in insert    root:  # in normal, @ in insert
VI_MODE=ins

# Override isg theme's caret to react to vi mode. Color rules mirror the original.
__isg::current_caret () {
   local color sign
   if [[ "$USER" == 'root' ]] || [[ "$(id -u "$USER")" == 0 ]]; then
      color='red'
      [[ $VI_MODE == ins ]] && sign='@' || sign='#'
   else
      [[ "$ISG_THEME_MODE" == 'dark' ]] && color='white' || color='black'
      [[ $VI_MODE == ins ]] && sign='›' || sign='»'
   fi
   echo "%{$fg[$color]%}$sign%{$reset_color%}"
}

function zle-keymap-select {
   case $KEYMAP in
      vicmd)      VI_MODE=cmd; print -n '\e[2 q' ;;
      main|viins) VI_MODE=ins; print -n '\e[6 q' ;;
   esac
   zle reset-prompt
}
function zle-line-init { VI_MODE=ins; print -n '\e[6 q' }
function zle-line-finish { print -n '\e[2 q' }
zle -N zle-keymap-select
zle -N zle-line-init
zle -N zle-line-finish
