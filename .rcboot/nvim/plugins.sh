#!/usr/bin/env bash
# Component: lazy.nvim and the Neovim plugins (shared)

_lazy_path() {
    echo "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
}

ensure_nvim_plugins() {
    echo "[STEP] Verifying Neovim plugins..."
    if [ -d "$(_lazy_path)" ]; then
        echo "[OK] lazy.nvim installed"
    else
        echo "[FAIL] lazy.nvim not found ($(_lazy_path) missing)"
        return 1
    fi
}

# The clone used to happen in nvim's own startup; a config only loads
# plugins, it does not fetch them, so without this nvim starts plain.
install_nvim_plugins() {
    echo "[STEP] Installing Neovim plugins..."
    if [ ! -d "$(_lazy_path)" ]; then
        git clone --filter=blob:none --branch=stable \
            https://github.com/folke/lazy.nvim.git "$(_lazy_path)"
    fi
    if nvim --headless "+Lazy! sync" +qa; then
        echo "[OK] Neovim plugins installed"
    else
        echo "[WARN] Neovim plugin install failed — run" \
            "'nvim --headless \"+Lazy! sync\" +qa' to see why"
    fi
}
