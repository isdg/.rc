#!/usr/bin/env bash
# Links: delta's git config into ~/.config/git, and its active theme inside
# the repo. .gitconfig includes the first, which includes the second.

seed_delta_theme() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}" mode
    [ -d "$dotfiles_dir/delta" ] || return 0
    mode="$(_theme_mode)"
    ln -sf "theme-$mode.gitconfig" "$dotfiles_dir/delta/theme-active.gitconfig"
    echo "[OK] Seeded delta/theme-active.gitconfig -> theme-$mode.gitconfig"
}

_links_delta() {
    local d="${DOTFILES_DIR:-$HOME/.rc}"
    local dst="$HOME/.config/git/delta.gitconfig"
    echo "delta.gitconfig|file|$d/delta/delta.gitconfig|$dst"
}
RC_LINK_SOURCES+=(_links_delta)

RC_LINK_HOOKS+=("seed_delta_theme|")
