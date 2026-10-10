#!/usr/bin/env bash
# Component: Fonts installation
# Requires: DOTFILES_DIR to be set

ensure_fonts_darwin() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    echo "[STEP] Verifying fonts..."
    if [ ! -d "$dotfiles_dir/fonts" ]; then
        echo "[SKIP] fonts/ directory not found in dotfiles"
        return 0
    fi
    local failed=0
    for font_file in "$dotfiles_dir/fonts"/*.ttf "$dotfiles_dir/fonts"/*.otf; do
        [ -f "$font_file" ] || continue
        local base
        base="$(basename "$font_file")"
        if [ -f "$HOME/Library/Fonts/$base" ]; then
            echo "[OK] Font: $base"
        else
            echo "[FAIL] Font missing: $base"
            failed=1
        fi
    done
    return $failed
}

ensure_fonts_linux() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    echo "[STEP] Verifying fonts..."
    if [ ! -d "$dotfiles_dir/fonts" ]; then
        echo "[SKIP] fonts/ directory not found in dotfiles"
        return 0
    fi
    local failed=0
    for font_file in "$dotfiles_dir/fonts"/*.ttf "$dotfiles_dir/fonts"/*.otf; do
        [ -f "$font_file" ] || continue
        local base
        base="$(basename "$font_file")"
        if [ -f "$HOME/.local/share/fonts/$base" ]; then
            echo "[OK] Font: $base"
        else
            echo "[FAIL] Font missing: $base"
            failed=1
        fi
    done
    return $failed
}

install_fonts_darwin() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"

    echo "[STEP] Installing fonts..."

    mkdir -p "$HOME/Library/Fonts"

    if [ -d "$dotfiles_dir/fonts" ]; then
        cp -n "$dotfiles_dir/fonts"/*.ttf "$HOME/Library/Fonts/" 2>/dev/null || true
        cp -n "$dotfiles_dir/fonts"/*.otf "$HOME/Library/Fonts/" 2>/dev/null || true
        echo "[OK] Fonts installed"
    else
        echo "[SKIP] fonts/ directory not found"
    fi
}

install_fonts_linux() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"

    echo "[STEP] Installing fonts..."

    mkdir -p "$HOME/.local/share/fonts"

    if [ -d "$dotfiles_dir/fonts" ]; then
        cp -n "$dotfiles_dir/fonts"/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true
        cp -n "$dotfiles_dir/fonts"/*.otf "$HOME/.local/share/fonts/" 2>/dev/null || true
        fc-cache -f 2>/dev/null || true
        echo "[OK] Fonts installed"
    else
        echo "[SKIP] fonts/ directory not found"
    fi
}
