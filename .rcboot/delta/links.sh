#!/usr/bin/env bash
# Links: delta's active theme, inside the repo. .gitconfig includes it.

seed_delta_theme() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}" mode
    [ -d "$dotfiles_dir/delta" ] || return 0
    mode="$(_theme_mode)"
    ln -sf "theme-$mode.gitconfig" "$dotfiles_dir/delta/theme-active.gitconfig"
    echo "[OK] Seeded delta/theme-active.gitconfig -> theme-$mode.gitconfig"
}
RC_LINK_HOOKS+=("seed_delta_theme|")
