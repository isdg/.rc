# escape hatch — `ZSH_BARE=1 zsh` skips this entire config: no oh-my-zsh,
# theme, banner, plugins or highlighting; a bare shell for testing
[[ -n $ZSH_BARE ]] && return

# startup timing — read by log_shell (startup.zsh) at render
zmodload zsh/datetime
typeset -gF _BANNER_T0=$EPOCHREALTIME

# Repo root, resolved from THIS file's real path so the config works under any
# directory name (~/.dotfiles, ~/.rc, …) — not just a hardcoded one. %x = the
# file being sourced; :A resolves the ~/.zshrc symlink to the repo; :h:h climbs
# zsh/ up to the repo root. Exported so children (tmux, scripts) can use it too.
export ISG_DOTFILES="${${(%):-%x}:A:h:h}"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#
#
ZSH_THEME="isg"
# Theme mode (dark|light) read from the single source of truth written by
# toggle_theme.sh. New shells always reflect the current theme and no tracked
# file is rewritten on toggle. Falls back to light if the file is missing.
ISG_THEME_MODE="$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/isg/theme" 2>/dev/null || echo light)"
ISG_DEFAULT_USER=true # show user name
#
#
# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# ── init: lite (ZSH_LITE=1) or oh-my-zsh ──
# The lite path replaces oh-my-zsh with the few things this config
# actually uses from it: colors, completion, history, prompt_subst,
# git_prompt_info and the theme. Compare: `ZSH_LITE=1 zsh` vs `zsh`.
if [[ -n $ZSH_LITE ]]; then
    setopt prompt_subst interactive_comments extended_glob auto_cd
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
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}'

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

    source "$ISG_DOTFILES/zsh/isg.zsh-theme"
else
    plugins=(git)
    source $ZSH/oh-my-zsh.sh
fi

# keep the whole history — both init paths above default SAVEHIST to 10k,
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

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#
# alias python=/Library/Frameworks/Python.framework/Versions/3.10/bin/python3
#alias python=/usr/local/bin/python3
# export PATH="$HOME/nvim/bin:$PATH"

# Created by `pipx` on 2024-06-11 08:50:53
export PATH="$PATH:/Users/isg/.local/bin"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide — frecency directory jumping. `z foo` jumps to the best match, `zi foo`
# picks via fzf. Builtin `cd` is left intact (no surprise remap).
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

export PATH="/usr/local/opt/llvm@17/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"   # cargo-installed binaries (plc)



export EDITOR='nvim'
export VISUAL='nvim'

source "$ISG_DOTFILES/zsh/aliases.zsh"
source "$ISG_DOTFILES/zsh/fzf.zsh"
source "$ISG_DOTFILES/zsh/vimode.zsh"
source "$ISG_DOTFILES/zsh/omni.zsh"



#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Syntax highlighting (Homebrew) — prefix derived from brew's own path
# (/usr/local/bin/brew → /usr/local) instead of the slow `brew --prefix`
_brew_prefix="${HOMEBREW_PREFIX:-${commands[brew]:h:h}}"
if [[ -f "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
unset _brew_prefix

# ── startup banner (engine lives in the isg theme) ──
source "$ISG_DOTFILES/zsh/startup.zsh"

banner_info "%Bisg%b · zsh"
banner_info "%D{%a %d %b %Y · %H:%M}"
_banner_branch=$(command git symbolic-ref --short HEAD 2>/dev/null)
banner_info "%~${_banner_branch:+ · $_banner_branch}"
unset _banner_branch
banner_render
