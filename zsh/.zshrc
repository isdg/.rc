# escape hatch — `ZSH_BARE=1 zsh` skips this entire config: no theme, banner,
# plugins or highlighting; a bare shell for testing
[[ -n $ZSH_BARE ]] && return

# startup timing — read by log_shell (startup.zsh) at render
zmodload zsh/datetime
typeset -gF _BANNER_T0=$EPOCHREALTIME

# Repo root, resolved from THIS file's real path so the config works under any
# directory name (~/.rc, ~/.dotfiles, …) — not just a hardcoded one. %x = the
# file being sourced; :A resolves the ~/.zshrc symlink to the repo; :h:h climbs
# zsh/ up to the repo root. Exported so children (tmux, scripts) can use it too.
export ISGRC="${${(%):-%x}:A:h:h}"

# Theme mode (dark|light) read from the single source of truth written by
# toggle_theme.sh. New shells always reflect the current theme and no tracked
# file is rewritten on toggle. Falls back to light if the file is missing.
ISG_THEME_MODE="$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/isg/theme" 2>/dev/null || echo light)"
ISG_DEFAULT_USER=true # show user name

# ── init ──
# Plain zsh — oh-my-zsh was dropped (Aug 2026). Measured: it cost ~141 ms of a
# ~480 ms warm startup and 17 MB, and nearly all of that went to compaudit, a
# second compdump and 21 lib files — not to the parts worth having. Those are
# reproduced by hand below (options, completion styles, key bindings, URL
# quoting) at no measurable cost. Its git aliases were in use and are vendored
# in zsh/git.zsh.
# auto_cd is deliberately NOT set. It turns any command zsh cannot run into a
# cd when a directory of that name happens to sit in $PWD, which reads as the
# shell doing something at random. The case that gave it away: `t` is aliased to
# tig, and on a box where tig was not installed, typing `t` in ~/.rc silently
# moved the shell into ~/.rc/tig — the repo's tig *config* directory — instead
# of saying "command not found". Every subdirectory here (fzf, theme, prompt,
# tig) is a loaded gun of that kind. dirs.zsh defines `..` explicitly instead.
setopt prompt_subst interactive_comments extended_glob

# options oh-my-zsh's libs set that are worth keeping
setopt auto_pushd pushd_ignore_dups pushd_minus  # cd builds a stack: cd -2, dirs -v
setopt always_to_end complete_in_word            # completion cursor behaviour
setopt hist_verify                               # !! expands for review, not instantly
setopt no_flow_control                           # frees Ctrl-S / Ctrl-Q
setopt long_list_jobs

autoload -Uz colors add-zsh-hook && colors

# history (oh-my-zsh defaults)
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history hist_expire_dups_first hist_ignore_dups \
       hist_ignore_space inc_append_history share_history

# completion — full fpath scan at most once a day, cached -C otherwise
autoload -Uz compinit
if [[ -n $HOME/.zcompdump-lite(#qN.mh-24) ]]; then
    compinit -C -d "$HOME/.zcompdump-lite"
else
    compinit -d "$HOME/.zcompdump-lite"
fi
autoload -Uz bashcompinit && bashcompinit   # tools that ship only bash completions

zstyle ':completion:*' menu select
# oh-my-zsh's matcher-list: exact, then case-insensitive, then partial-word —
# strictly richer than the single case-fold rule this config had before.
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# Quote ? & * in URLs as they are typed, so they don't glob-explode. This is the
# self-insert half of oh-my-zsh's magic functions; the bracketed-paste half is
# deliberately left out — it is slow with zsh-syntax-highlighting on large
# pastes, and paste timing here is already delicate (see KEYTIMEOUT in vimode.zsh).
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# minimal git_prompt_info — the one oh-my-zsh function the theme uses
git_prompt_info() {
    local ref
    ref=$(command git symbolic-ref --short HEAD 2>/dev/null) ||
    ref=$(command git rev-parse --short HEAD 2>/dev/null) || return 0
    local state=$ZSH_THEME_GIT_PROMPT_CLEAN
    [[ -n $(command git status --porcelain 2>/dev/null | head -1) ]] &&
        state=$ZSH_THEME_GIT_PROMPT_DIRTY
    echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${state}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

source "$ISGRC/zsh/isg.zsh-theme"

# oh-my-zsh's ls/grep colour aliases. -G is BSD/macOS; GNU ls wants --color,
# where -G means "hide group" instead — pick by OSTYPE rather than probing, so
# this costs no subprocess (oh-my-zsh ran `ls --color=tty` to decide).
if [[ $OSTYPE == darwin* || $OSTYPE == *bsd* ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=tty'
fi
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
alias history='fc -l 1'

# keep the whole history — the init block above defaults SAVEHIST to 10k,
# which trims the file (recovered Jun 2026 after a wipe; see .zsh_history.bak-*)
SAVEHIST=50000

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Personal aliases live in zsh/aliases.zsh (sourced below).
# For a full list of active aliases, run `alias`.
#
# alias python=/Library/Frameworks/Python.framework/Versions/3.10/bin/python3
#alias python=/usr/local/bin/python3
# export PATH="$HOME/nvim/bin:$PATH"

# ~/.local/bin — pipx (which added this line in 2024, hardcoded to the macOS
# $HOME and so dead on every Linux box), and the newer Neovim the Linux
# bootstrap drops there when the distro's package is too old. Prepended, not
# appended: the whole point is to beat an older /usr/bin copy.
export PATH="$HOME/.local/bin:$PATH"

# fzf. ~/.fzf/bin goes first for the same reason: on a distro that also packages
# fzf (Debian bookworm ships 0.38) the clone's modern binary has to win, or
# ~/.fzf.zsh's `fzf --zsh` fails with "unknown option: --zsh" — leaving ^R bound
# to redisplay and $FZF_DEFAULT_OPTS_FILE (fzf >= 0.48, set in .zshenv) ignored,
# so every picker loses its colours too. fzf's own installer appends this, which
# is precisely the bug.
[[ -d $HOME/.fzf/bin ]] && export PATH="$HOME/.fzf/bin:$PATH"

if [[ -f ~/.fzf.zsh ]]; then
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

# zoxide — frecency directory jumping. `z foo` jumps to the best match, `zi foo`
# picks via fzf. Builtin `cd` is left intact (no surprise remap).
#
# Deprecated (Aug 2026): the bootstraps no longer install it. This init stays
# because it is already guarded — machines that still have zoxide keep `z`, and
# a fresh box simply skips the line.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

export PATH="/usr/local/opt/llvm@17/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"   # cargo-installed binaries (plc)



export EDITOR='nvim'
export VISUAL='nvim'

# gpg-agent's pinentry needs a tty to prompt on. Without this, commit signing
# (git_signing.sh leaves it on whenever the key is present) hangs silently
# instead of asking for the passphrase.
export GPG_TTY=$(tty)

source "$ISGRC/zsh/git.zsh"      # both before aliases.zsh, so personal
source "$ISGRC/zsh/dirs.zsh"     # aliases keep precedence
source "$ISGRC/zsh/aliases.zsh"
source "$ISGRC/zsh/fzf.zsh"
source "$ISGRC/zsh/vimode.zsh"
source "$ISGRC/zsh/omni.zsh"

# Up/Down search history by the prefix already typed — the one oh-my-zsh binding
# that is genuinely missed. Must come after vimode.zsh: its `bindkey -v`
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



#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Syntax highlighting — Homebrew on darwin (prefix derived from brew's own path,
# /usr/local/bin/brew → /usr/local, instead of the slow `brew --prefix`), or the
# git clone that bootstrap/components/zsh_syntax_linux.sh makes on Linux.
_brew_prefix="${HOMEBREW_PREFIX:-${commands[brew]:h:h}}"
for _hl in "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
           "$HOME/.local/share/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
    [[ -f $_hl ]] && { source "$_hl"; break }
done
unset _brew_prefix _hl

# ── startup banner (engine lives in the isg theme) ──
source "$ISGRC/zsh/startup.zsh"

banner_info "%Bisg%b · $(banner_host_info)"
banner_info "%D{%a %d %b %Y · %H:%M}"
_banner_branch=$(command git symbolic-ref --short HEAD 2>/dev/null)
banner_info "%~${_banner_branch:+ · $_banner_branch}"
unset _banner_branch
banner_render

# Skip cosmos-saas's sync-env git hook (post-merge / post-checkout).
# It runs `asdf plugin add supabase` on every merge/checkout because the
# .tool-versions pin (2.101.0) can never match the Homebrew supabase on PATH.
# Remove this line to restore it; run `uv sync` by hand when uv.lock changes.
export LEFTHOOK_EXCLUDE=sync-env
