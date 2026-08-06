#!/usr/bin/env bash
# Component: Keyboard remap (via hidutil UserKeyMapping)
#   Right Command -> Return
#   Caps Lock     <-> Backspace  (swap)
# Requires: DOTFILES_DIR to be set

ensure_keyremap_darwin() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    local src="$dotfiles_dir/darwin/keyremap/com.local.KeyRemap.plist"
    local dst="$HOME/Library/LaunchAgents/com.local.KeyRemap.plist"
    echo "[STEP] Verifying keyboard remap..."
    if [ ! -f "$src" ]; then
        echo "[SKIP] $src not found in dotfiles"
        return 0
    fi
    _check_link "com.local.KeyRemap.plist" "$dst" "$src" || return 1
}

install_keyremap_darwin() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    local src="$dotfiles_dir/darwin/keyremap/com.local.KeyRemap.plist"
    local dst_dir="$HOME/Library/LaunchAgents"
    local dst="$dst_dir/com.local.KeyRemap.plist"

    echo "[STEP] Installing keyboard remap LaunchAgent..."

    if [ ! -f "$src" ]; then
        echo "[SKIP] $src not found"
        return
    fi

    mkdir -p "$dst_dir"
    ln -sf "$src" "$dst"
    echo "[OK] Linked com.local.KeyRemap.plist"

    local domain="gui/$(id -u)"
    launchctl bootout "$domain/com.local.KeyRemap" 2>/dev/null || true
    if launchctl bootstrap "$domain" "$dst" 2>/dev/null; then
        echo "[OK] LaunchAgent loaded"
    else
        echo "[WARN] Could not load LaunchAgent (will run on next login)"
    fi
}
