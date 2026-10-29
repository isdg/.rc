#
# isg ZSH Theme
#
# Forked from Sobole ZSH Theme by Nikita Sobolev (github.com/sobolevn)
# Original: https://github.com/sobolevn/sobole-zsh-theme
# License: WTFPL

# Testing colors:
#
# for i in {0..255} ; do
#   printf "\x1b[48;5;%sm%3d\e[0m " "$i" "$i"
#   if (( i == 15 )) || (( i > 15 )) && (( (i-15) % 6 == 0 )); then
#     printf "\n";
#   fi
# done

# ----------------------------------------------------------------------------
# PROMPT settings
# These settings changes how your terminal prompt looks like
# ----------------------------------------------------------------------------

PROMPT='$(__isg::top_line)
$(__isg::current_caret) '

PROMPT2='. '

# No RPROMPT: the exit-status segment that lived here shouted `130 ⚠️` on every
# fzf Esc and Ctrl-C as loudly as on a real failure. `echo $?` on demand instead.

__isg::top_line () {
  # RPROMPT only reaches the last line, so the date stamp is right-aligned
  # here by padding; one column spare, as ZLE_RPROMPT_INDENT does.
  setopt localoptions extendedglob
  local left right lw rw
  left="$(__isg::current_venv)$(__isg::user_info)$(__isg::current_dir)"
  left+=" $(git_prompt_info)"
  right=${(%):-'%D{%Y-%m-%d %H:%M:%S %z}'}
  lw=${(m)#${${(%)left}//$'\e'\[[0-9;]#m/}}
  rw=${(m)#right}
  local pad=$(( COLUMNS - lw - rw - 1 ))
  # The tmux status bar's grey: ISG_UI_FG in theme/palette.sh.
  local grey='#555555'
  [[ "$ISG_THEME_MODE" == 'dark' ]] && grey='#c0c0c0'
  if (( pad > 0 )); then
    print -rn -- "$left${(l:pad:)}%F{$grey}$right%f"
  else
    print -rn -- "$left"
  fi
}

__isg::current_caret () {
  # This function sets caret color and sign
  # based on theme and privileges.
  if [[ "$USER" == 'root' ]] || [[ "$(id -u "$USER")" == 0 ]]; then
    CARET_COLOR='red'
    CARET_SIGN='#'
  else
    CARET_SIGN='»'

    if [[ "$ISG_THEME_MODE" == 'dark' ]]; then
      CARET_COLOR='white'
    else
      CARET_COLOR='black'
    fi
  fi

  echo "%{$fg[$CARET_COLOR]%}$CARET_SIGN%{$reset_color%}"
}

__isg::current_dir () {
  # Settings up current directory and settings max width for it:
  local max_pwd_length="${ISG_MAX_DIR_LEN:-65}"
  local color

  color='blue'

  if [[ $(echo -n "$PWD" | wc -c) -gt "$max_pwd_length" ]]; then
    echo "%{$fg_bold[$color]%}%-1~ ... %2~%{$reset_color%} "
  else
    echo "%{$fg_bold[$color]%}%~%{$reset_color%} "
  fi
}

__isg::user_info () {
  if [[ -n "$SSH_TTY" ]] || [[ -n "$SSH_CONNECTION" ]]; then
    echo "$fg[green]#$reset_color$USER "
  elif [[ ! -z "$ISG_DEFAULT_USER" ]] &&
     [[ "$USER" != "$ISG_DEFAULT_USER" ]]; then
    echo "@$USER "
  fi
}

# ----------------------------------------------------------------------------
# virtualenv settings
# These settings changes how virtualenv is displayed.
# ----------------------------------------------------------------------------

# Disable the standard prompt:
export VIRTUAL_ENV_DISABLE_PROMPT=1

__isg::current_venv () {
  # Despite the fact that `_OLD_VIRTUAL_PATH` is undocumented, it is always
  # set in `activate` script. It is needed to fix `vscode` terminal.
  if [[ ! -z "$VIRTUAL_ENV" ]] && [[ ! -z "$_OLD_VIRTUAL_PATH" ]]; then
    # Show this info only if virtualenv is activated:
    local dir=$(basename "$VIRTUAL_ENV")
    echo "($dir) "
  fi
}

# ----------------------------------------------------------------------------
# VCS specific colors and icons
# These settings defines how icons and text is displayed for
# vcs-related stuff. We support only `git`.
# ----------------------------------------------------------------------------

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
# ASCII, not ✗/✔: * for a dirty tree is git's own convention (__git_ps1 marks
# unstaged work with it), and both glyphs survive a terminal or font that has
# no opinion about U+2714.
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}=%{$reset_color%}"
# Ahead of / behind the upstream. Yellow for work you have not pushed, since it
# is the one that is yours to act on; blue for commits waiting to come down.
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[cyan]%}§%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}✚%{$reset_color%}"

# ----------------------------------------------------------------------------
# `ls` colors
# Made with: http://geoff.greer.fm/lscolors/
# ----------------------------------------------------------------------------

export LSCOLORS='exfxcxdxBxegedabagacab'
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;41'

# Turns on colors with default unix `ls` command:
export CLICOLOR=1

# ----------------------------------------------------------------------------
# `grep` colors and options
# ----------------------------------------------------------------------------

export GREP_COLORS='mt=1;35'

# ----------------------------------------------------------------------------
# `zstyle` colors
# Internal zsh styles: completions, suggestions, etc
# ----------------------------------------------------------------------------

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# ----------------------------------------------------------------------------
# zsh-syntax-highlighting, fzf, and bat tweaks
# This setting works only if `$ISG_SYNTAX_HIGHLIGHTING` is not false.
# Each tool is only modified if installed.
# ----------------------------------------------------------------------------

if [[ "$ISG_SYNTAX_HIGHLIGHTING" != 'false' ]]; then
  typeset -A ZSH_HIGHLIGHT_STYLES

  # Disable strings highlighting:
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='none'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='none'

  if [[ "$ISG_THEME_MODE" == 'dark' ]]; then
    ZSH_HIGHLIGHT_STYLES[path]='fg=white,underline'
  fi

  # Custom bat/syntect themes that mirror the vim colorschemes exactly, so
  # fzf/bat previews match the editor (see bat/themes/vs_*.tmTheme). Override
  # per-mode with ISG_SYNTAX_THEME_DARK / ISG_SYNTAX_THEME_LIGHT.
  if [[ "$ISG_THEME_MODE" == 'dark' ]]; then
    export ISG_SYNTAX_THEME="${ISG_SYNTAX_THEME_DARK:-vs_dark}"
  else
    export ISG_SYNTAX_THEME="${ISG_SYNTAX_THEME_LIGHT:-vs_light}"
  fi

  # If `bat` is installed, then change the theme for it:
  # https://github.com/sharkdp/bat
  if (( $+commands[bat] )); then
    export BAT_THEME="$ISG_SYNTAX_THEME"
  fi
fi

# ----------------------------------------------------------------------------
# less (and man) colors
# ----------------------------------------------------------------------------

if [[ "$ISG_LESS_THEME" != 'false' ]]; then
  if [[ "$ISG_THEME_MODE" == 'dark' ]]; then
    export LESS_TERMCAP_mb="$(printf '\e[1;35m')"
    export LESS_TERMCAP_md="$(printf '\e[1;35m')"
  else
    export LESS_TERMCAP_mb="$(printf '\e[1;34m')"
    export LESS_TERMCAP_md="$(printf '\e[1;34m')"
  fi
  export LESS_TERMCAP_me="$(printf '\e[0m')"
  export LESS_TERMCAP_se=$(printf '\e[0m')
  export LESS_TERMCAP_so=$(printf '\e[30m')
  export LESS_TERMCAP_ue=$(printf '\e[0m')
  export LESS_TERMCAP_us=$(printf '\e[1;32m')
  # Search matches only (the prompt keeps `so`): white on 256-colour red, which
  # stays vivid in both modes where ANSI 1 goes pink in dark.
  export LESS='--use-color -DS231.160'
fi

# ----------------------------------------------------------------------------
# zsh hooks
# ----------------------------------------------------------------------------

_ISG_ADD_LINE_SEPARATOR='false'

__isg::preexec () {
  if [[ $# -eq 0 ]] || [[ "$2" == 'clear' ]]; then
    _ISG_ADD_LINE_SEPARATOR='false'
  else
    _ISG_ADD_LINE_SEPARATOR='true'
  fi
}

__isg::precmd () {
  local cmd_result="$?"
  if [[ "$_ISG_ADD_LINE_SEPARATOR" == 'true' ]] ||
     [[ "$cmd_result" -ne 0 ]]; then
    print
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec __isg::preexec
add-zsh-hook precmd __isg::precmd
