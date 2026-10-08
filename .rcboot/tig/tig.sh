#!/usr/bin/env bash
# Component: Tig config (shared)
# Requires: DOTFILES_DIR to be set

ensure_tig() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    local failed=0
    echo "[STEP] Verifying tig..."

    # The binary, not just the rc file. Checking only the symlink reported a
    # clean "[OK] Linked .tigrc" on a box with no tig installed at all.
    if command -v tig > /dev/null 2>&1; then
        echo "[OK] tig installed ($(command -v tig))"
    else
        echo "[FAIL] tig not installed (only its .tigrc is linked)"
        failed=1
    fi

    if [ -f "$dotfiles_dir/tig/.tigrc" ]; then
        _check_link ".tigrc" "$HOME/.tigrc" "$dotfiles_dir/tig/.tigrc" || failed=1
    else
        echo "[SKIP] tig/.tigrc not found in dotfiles"
    fi

    return $failed
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
