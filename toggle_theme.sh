#!/bin/bash
# Toggle themes for Vim, Zsh, and Hyper (macOS)

HYPER="$HOME/.hyper.js"
GHOSTTY="$HOME/.config/ghostty/config"
TMUX_CONF="$HOME/.tmux.conf"
NOM="$HOME/Library/Application Support/nom/config.yml"

# Resolve symlinks
REAL_HYPER="$(readlink "$HYPER" || echo "$HYPER")"
REAL_GHOSTTY="$(readlink "$GHOSTTY" || echo "$GHOSTTY")"
REAL_NOM="$(readlink "$NOM" || echo "$NOM")"
# config is itself in a symlinked dir; resolve fully
[ -L "$REAL_GHOSTTY" ] || REAL_GHOSTTY="$(cd "$(dirname "$GHOSTTY")" && pwd -P)/$(basename "$GHOSTTY")"

STATUS=""

# --- Source of truth: flip the mode file ---
# Everything derives from this one untracked file. zsh (-> bat/less/ls), ghostty,
# vim and nvim all READ it at startup, so toggling rewrites no tracked file for
# them. Apps further down that lack a read path are still set from $MODE.
THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/isg/theme"
cur="$(cat "$THEME_FILE" 2>/dev/null || echo light)"
[ "$cur" = dark ] && MODE=light || MODE=dark
mkdir -p "$(dirname "$THEME_FILE")"
echo "$MODE" > "$THEME_FILE"
STATUS+="mode: $cur -> $MODE\n"
STATUS+="Vim/Neovim: vs_$MODE (on next start)\n"
STATUS+="Zsh/bat: $MODE (new shells; 'exec zsh' to refresh open ones)\n"

# --- Hyper: toggle comment on localPlugins ---
if grep -q '^[[:space:]]*localPlugins:[[:space:]]*\["light"\],' "$REAL_HYPER"; then
    sed -i '' 's/^[[:space:]]*localPlugins:[[:space:]]*\["light"\],/   \/\/ localPlugins: ["light"],/' "$REAL_HYPER"
    STATUS+="Hyper: dark\n"
elif grep -q '^[[:space:]]*\/\/ localPlugins:[[:space:]]*\["light"\],' "$REAL_HYPER"; then
    sed -i '' 's/^[[:space:]]*\/\/ localPlugins:[[:space:]]*\["light"\],/   localPlugins: ["light"],/' "$REAL_HYPER"
    STATUS+="Hyper: light\n"
else
    STATUS+="Hyper: localPlugins not found\n"
fi

# --- Ghostty: select theme via the theme-active.conf include symlink ---
# One symlink swap replaces five seds on the tracked config; theme-active.conf
# is gitignored, so toggling never dirties the repo.
if [ -f "$REAL_GHOSTTY" ]; then
    GHOSTTY_DIR="$(dirname "$REAL_GHOSTTY")"
    ln -sf "theme-$MODE.conf" "$GHOSTTY_DIR/theme-active.conf"
    STATUS+="Ghostty: $MODE (reload open windows with cmd+shift+,)\n"
else
    STATUS+="Ghostty: config not found\n"
fi

# --- Tmux: re-source so the if-shell re-reads the mode file and repaints ---
# The styles live in tmux/theme-{dark,light}.conf; nothing is sed'd here.
if tmux source-file "$TMUX_CONF" 2>/dev/null; then
    STATUS+="Tmux: $MODE (reloaded)\n"
else
    STATUS+="Tmux: $MODE (on next start)\n"
fi

# --- nom (RSS reader): toggle glamour theme (article rendering) ---
if [ -f "$REAL_NOM" ]; then
    if grep -q "^  glamour: light" "$REAL_NOM"; then
        sed -i '' 's/^  glamour: light/  glamour: dark/' "$REAL_NOM"
        STATUS+="nom: dark\n"
    elif grep -q "^  glamour: dark" "$REAL_NOM"; then
        sed -i '' 's/^  glamour: dark/  glamour: light/' "$REAL_NOM"
        STATUS+="nom: light\n"
    else
        STATUS+="nom: glamour line not found\n"
    fi
else
    STATUS+="nom: config not found\n"
fi

# --- Splash: mascot + status, banner-style (mascots.sh) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/mascots.sh"
clear
splash_render "$MODE" "$STATUS"
