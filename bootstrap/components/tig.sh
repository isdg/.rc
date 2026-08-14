#!/usr/bin/env bash
# Component: Tig config (shared)
# Requires: DOTFILES_DIR to be set

ensure_tig() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    echo "[STEP] Verifying tig..."
    if [ -f "$dotfiles_dir/tig/.tigrc" ]; then
        _check_link ".tigrc" "$HOME/.tigrc" "$dotfiles_dir/tig/.tigrc" || return 1
    else
        echo "[SKIP] tig/.tigrc not found in dotfiles"
    fi
}

link_tig() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"

    echo "[STEP] Setting up tig..."

    if [ -f "$dotfiles_dir/tig/.tigrc" ]; then
        ln -sf "$dotfiles_dir/tig/.tigrc" "$HOME/.tigrc"
        echo "[OK] Linked .tigrc"
    else
        echo "[SKIP] tig/.tigrc not found"
    fi
}
