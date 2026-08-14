#!/usr/bin/env bash
# Component: zsh-syntax-highlighting (Linux only - Darwin uses homebrew)
# Installs into ~/.local/share/zsh. It used to be cloned into the oh-my-zsh
# tree, which .zshrc never sourced — only the Homebrew path was checked — so
# highlighting was silently absent on Linux. .zshrc now checks both.

_zsh_syntax_dir() { echo "$HOME/.local/share/zsh/zsh-syntax-highlighting"; }

ensure_zsh_syntax_linux() {
    local zsh_syntax_dir; zsh_syntax_dir="$(_zsh_syntax_dir)"
    echo "[STEP] Verifying zsh-syntax-highlighting..."
    if [ -f "$zsh_syntax_dir/zsh-syntax-highlighting.zsh" ]; then
        echo "[OK] zsh-syntax-highlighting installed"
    else
        echo "[FAIL] zsh-syntax-highlighting not installed ($zsh_syntax_dir missing)"
        return 1
    fi
}

install_zsh_syntax_linux() {
    echo "[STEP] Installing zsh-syntax-highlighting..."

    local zsh_syntax_dir; zsh_syntax_dir="$(_zsh_syntax_dir)"

    if [ ! -d "$zsh_syntax_dir" ]; then
        mkdir -p "$(dirname "$zsh_syntax_dir")"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_syntax_dir"
        echo "[OK] zsh-syntax-highlighting installed"
    else
        echo "[SKIP] zsh-syntax-highlighting already installed"
    fi
}
