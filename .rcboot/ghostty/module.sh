#!/usr/bin/env bash
# Module: ghostty — the config dir, plus the two includes it needs seeded.

link ghostty "$HOME/.config/ghostty"

seed_ghostty() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    local mode
    mode="$(_theme_mode)"

    # Active-theme include. toggle_theme.sh maintains it afterwards.
    local active="$dotfiles_dir/ghostty/theme-active.conf"
    if [ ! -e "$active" ]; then
        ln -sf "theme-$mode.conf" "$active"
        echo "[OK] Seeded ghostty/theme-active.conf -> theme-$mode.conf"
    fi

    # Ghostty width include. Seeded because a missing include is not ignored:
    # ghostty reports "error opening config-file ... FileNotFound" and drops
    # window-padding-x entirely, so the window opens with no padding at all.
    # padding.sh (alias `ww`) rewrites this file afterwards.
    local width_active="$dotfiles_dir/ghostty/width-active.conf"
    if [ ! -f "$width_active" ]; then
        bash "$dotfiles_dir/sh/padding.sh" x 400 >/dev/null
        echo "[OK] Seeded ghostty/width-active.conf (window-padding-x = 400)"
    fi
}
hook seed_ghostty
