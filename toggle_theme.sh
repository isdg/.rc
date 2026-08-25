#!/bin/bash
# Toggle light/dark for Vim/Neovim, Zsh, Ghostty, and tmux (macOS)

GHOSTTY="$HOME/.config/ghostty/config"
TMUX_CONF="$HOME/.tmux.conf"

# Resolve symlinks
REAL_GHOSTTY="$(readlink "$GHOSTTY" || echo "$GHOSTTY")"
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
STATUS+="Vim/Neovim: vs_$MODE (on new session)\n"
STATUS+="Zsh/bat: $MODE (on new zsh)\n"

# --- Ghostty: select theme via the theme-active.conf include symlink ---
# One symlink swap replaces five seds on the tracked config; theme-active.conf
# is gitignored, so toggling never dirties the repo.
if [ -f "$REAL_GHOSTTY" ]; then
    GHOSTTY_DIR="$(dirname "$REAL_GHOSTTY")"
    ln -sf "theme-$MODE.conf" "$GHOSTTY_DIR/theme-active.conf"
    STATUS+="Ghostty: $MODE (on new reload)\n"
else
    STATUS+="Ghostty: config not found\n"
fi

# --- k9s: swap the skin-active.yaml symlink (config.yaml points ui.skin at it) ---
# Same idiom as Ghostty: one symlink swap, no tracked file rewritten. k9s picks
# it up on next launch (or live if k9s.ui.reactive is true).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K9S_SKINS="$SCRIPT_DIR/k9s/skins"
if [ -d "$K9S_SKINS" ]; then
    ln -sf "vs_$MODE.yaml" "$K9S_SKINS/skin-active.yaml"
    STATUS+="k9s: $MODE (on new session)\n"
fi

# --- tig: swap the theme-active.tigrc symlink (.tigrc sources it with -q) ---
# Same idiom again. Only the cursor line differs per mode — ANSI blue is pale
# under the dark palette, so white-on-blue is unreadable there.
TIG_DIR="$SCRIPT_DIR/tig"
if [ -d "$TIG_DIR" ]; then
    ln -sf "theme-$MODE.tigrc" "$TIG_DIR/theme-active.tigrc"
    STATUS+="tig: $MODE (on new tig)\n"
fi

# --- fzf: swap the opts-active.conf symlink ($FZF_DEFAULT_OPTS_FILE points at
# it; see zsh/.zshenv). Same idiom once more, and the reason every fzf on the
# machine — our pickers, fzf-tab, nvim's fzf.vim, the ~/omni tmux popups —
# follows the toggle without being told about it individually. ---
FZF_DIR="$SCRIPT_DIR/fzf"
if [ -d "$FZF_DIR" ]; then
    ln -sf "opts-$MODE.conf" "$FZF_DIR/opts-active.conf"
    STATUS+="fzf: $MODE (on new fzf)\n"
fi

# --- Tmux: re-source so the if-shell re-reads the mode file and repaints ---
# The styles live in tmux/theme-{dark,light}.conf; nothing is sed'd here.
if tmux source-file "$TMUX_CONF" 2>/dev/null; then
    STATUS+="Tmux: $MODE (reloaded)\n"
else
    STATUS+="Tmux: $MODE (on new session)\n"
fi

# --- Splash: mascot + status, banner-style (mascots.sh) ---
# Printed where the cursor already is, NOT onto a cleared screen. Toggling the
# theme is something you do in the middle of working, and wiping the scrollback
# to announce it threw away whatever you were looking at — the command output
# that made you want more contrast in the first place.
# Nothing in splash_render positions the cursor (no \e[H, no \e[J); it only
# prints lines, so it appends cleanly wherever it lands.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/mascots.sh"
splash_render "$MODE" "$STATUS"
