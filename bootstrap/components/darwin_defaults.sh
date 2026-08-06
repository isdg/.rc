#!/usr/bin/env bash
# Component: Darwin defaults (Dock, etc.)
# Requires: DOTFILES_DIR to be set

ensure_darwin_defaults() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    local script="$dotfiles_dir/darwin/defaults.sh"
    echo "[STEP] Verifying Darwin defaults script..."
    if [ -f "$script" ]; then
        echo "[OK] darwin/defaults.sh present (defaults not re-verified — apply is idempotent)"
    else
        echo "[FAIL] darwin/defaults.sh not found"
        return 1
    fi
}

apply_darwin_defaults() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    local script="$dotfiles_dir/darwin/defaults.sh"

    echo "[STEP] Applying Darwin defaults..."

    if [ ! -f "$script" ]; then
        echo "[SKIP] $script not found"
        return
    fi

    if bash "$script"; then
        echo "[OK] Darwin defaults applied"
    else
        echo "[WARN] Darwin defaults had issues, continuing..."
    fi
}
