#!/usr/bin/env bash
# Component: fzf-tab (Linux only - Darwin uses homebrew)

FZF_TAB_TAG=v1.3.0

_fzf_tab_dir() { echo "$HOME/.local/share/zsh/fzf-tab"; }

_fzf_tab_tag() {
    git -C "$(_fzf_tab_dir)" describe --tags --exact-match 2>/dev/null
}

ensure_fzf_tab_linux() {
    echo "[STEP] Verifying fzf-tab..."
    local tag; tag="$(_fzf_tab_tag)"
    if [ "$tag" = "$FZF_TAB_TAG" ]; then
        echo "[OK] fzf-tab $FZF_TAB_TAG installed"
    else
        echo "[FAIL] fzf-tab at ${tag:-none}, want $FZF_TAB_TAG" \
            "($(_fzf_tab_dir))"
        return 1
    fi
}

install_fzf_tab_linux() {
    echo "[STEP] Installing fzf-tab..."
    local dir; dir="$(_fzf_tab_dir)"
    if [ ! -d "$dir" ]; then
        mkdir -p "$(dirname "$dir")"
        git -c advice.detachedHead=false clone -q --depth 1 \
            --branch "$FZF_TAB_TAG" https://github.com/Aloxaf/fzf-tab.git "$dir"
    elif [ "$(_fzf_tab_tag)" != "$FZF_TAB_TAG" ]; then
        git -C "$dir" fetch -q --depth 1 origin tag "$FZF_TAB_TAG"
        git -C "$dir" -c advice.detachedHead=false checkout -q "$FZF_TAB_TAG"
    else
        echo "[SKIP] fzf-tab $FZF_TAB_TAG already installed"
        return 0
    fi
    echo "[OK] fzf-tab $FZF_TAB_TAG installed"
}
