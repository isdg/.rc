# Theme mode (dark|light) read from the single source of truth written by
# toggle_theme.sh. New shells always reflect the current theme and no tracked
# file is rewritten on toggle. Falls back to light if the file is missing.
# $(<file) is read by zsh itself, no cat fork.
_isg_theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/isg/theme"
ISG_THEME_MODE=light
[[ -r $_isg_theme_file ]] && ISG_THEME_MODE="$(<$_isg_theme_file)"
unset _isg_theme_file
ISG_DEFAULT_USER=true # show user name
