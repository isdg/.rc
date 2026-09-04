#!/usr/bin/env bash
# statusLine command for Claude Code — mirrors the prompt built by
# zsh/isg.zsh-theme's PROMPT (venv → user → dir → git → caret).
# Kept in sync with that theme by hand — when the prompt changes, change here.

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
cd "$cwd" 2>/dev/null || true

# venv — mirrors __isg::current_venv (only shown once `activate` has run)
venv=''
if [[ -n "$VIRTUAL_ENV" ]] && [[ -n "$_OLD_VIRTUAL_PATH" ]]; then
    venv="($(basename "$VIRTUAL_ENV")) "
fi

# user — mirrors __isg::user_info: shown over ssh, or as a non-default user.
# Only the `#` is green there; the name itself takes the default foreground.
user_info=''
if [[ -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]; then
    user_info="$(printf '\033[32m')#$(printf '\033[0m')${USER} "
elif [[ -n "$ISG_DEFAULT_USER" && "$USER" != "$ISG_DEFAULT_USER" ]]; then
    user_info="@${USER} "
fi

# dir — mirrors __isg::current_dir: bold blue %~, and past $ISG_MAX_DIR_LEN
# bytes of $PWD the `%-1~ ... %2~` form instead. Both %-1~ and %2~ count
# components of the ~-substituted path, so truncate that rather than $cwd:
# under $HOME the leading component is `~`, not `/Users`.
tilde='~'
dir="${cwd/#$HOME/$tilde}"
if [[ ${#cwd} -gt ${ISG_MAX_DIR_LEN:-65} ]]; then
    IFS='/' read -r -a parts <<< "$dir"
    # %-1~: leftmost component — `~` under home, else `/<top-level>`
    if [[ $dir == "$tilde"* ]]; then first="$tilde"; else first="/${parts[1]}"; fi
    # %2~: the rightmost two
    n=${#parts[@]}
    last="${parts[n-2]}/${parts[n-1]}"
    dir="${first} ... ${last}"
fi

# git — mirrors git_prompt_info: green branch (or short sha), then the ascii
# glyph from ZSH_THEME_GIT_PROMPT_{DIRTY,CLEAN} — * red if dirty, = green if
# clean. Locks skipped so this never blocks on a concurrent git process.
git_status=''
if git --no-optional-locks rev-parse --git-dir >/dev/null 2>&1; then
    ref=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
        || git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    # oh-my-zsh's parse_git_dirty, which is what feeds DIRTY/CLEAN: porcelain
    # status, submodule content ignored. Untracked files count as dirty here
    # because DISABLE_UNTRACKED_FILES_DIRTY is not set in .zshrc.
    if [[ -z $(git --no-optional-locks status --porcelain \
        --ignore-submodules=dirty 2>/dev/null) ]]; then
        marker="$(printf '\033[32m')=$(printf '\033[0m')"
    else
        marker="$(printf '\033[31m')*$(printf '\033[0m')"
    fi
    git_status="$(printf '\033[32m')${ref}$(printf '\033[0m') ${marker}"
fi

# caret — mirrors __isg::current_caret: red # for root, else » colored for
# the saved theme mode (dark|light), read from the same file isg.zsh-theme
# reads at shell start.
theme_mode=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/isg/theme" 2>/dev/null || echo light)
if [[ "$USER" == root ]] || [[ "$(id -u "$USER" 2>/dev/null)" == 0 ]]; then
    caret="$(printf '\033[31m')#$(printf '\033[0m')"
elif [[ "$theme_mode" == dark ]]; then
    caret="$(printf '\033[37m')»$(printf '\033[0m')"
else
    caret="$(printf '\033[30m')»$(printf '\033[0m')"
fi

printf '%s%s%s%s%s %s\n%s ' \
    "$venv" "$user_info" "$(printf '\033[1;34m')" "$dir" "$(printf '\033[0m')" "$git_status" "$caret"
