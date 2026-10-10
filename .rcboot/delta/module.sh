#!/usr/bin/env bash
# Module: delta's git config into ~/.config/git, and its active theme inside
# the repo. .gitconfig includes the first, which includes the second.

seed_delta_theme() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}" mode
    [ -d "$dotfiles_dir/delta" ] || return 0
    mode="$(_theme_mode)"
    ln -sf "theme-$mode.gitconfig" "$dotfiles_dir/delta/theme-active.gitconfig"
    echo "[OK] Seeded delta/theme-active.gitconfig -> theme-$mode.gitconfig"
}

link delta/delta.gitconfig "$HOME/.config/git/delta.gitconfig"
hook seed_delta_theme
