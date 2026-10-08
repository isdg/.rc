#!/usr/bin/env bash
# Component: Vim plugins (shared)

ensure_vim_dirs() {
    echo "[STEP] Verifying Vim directories..."
    if [ -d "$HOME/.vim/colors" ]; then
        echo "[OK] $HOME/.vim/colors"
    else
        echo "[FAIL] $HOME/.vim/colors missing"
        return 1
    fi
}

# A real directory, so the color schemes get linked into it one file at a time.
create_vim_dirs() {
    echo "[STEP] Creating Vim directories..."
    mkdir -p "$HOME/.vim/colors"
    echo "[OK] Directories created"
}

ensure_vim_plugins() {
    echo "[STEP] Verifying Vim & Neovim plugins..."
    local failed=0
    local vim_plug_path="$HOME/.vim/autoload/plug.vim"
    if [ -f "$vim_plug_path" ]; then
        echo "[OK] vim-plug installed"
    else
        echo "[FAIL] vim-plug not installed ($vim_plug_path missing)"
        failed=1
    fi
    local lazy_path="$HOME/.local/share/nvim/lazy/lazy.nvim"
    if [ -d "$lazy_path" ]; then
        echo "[OK] lazy.nvim installed"
    else
        echo "[FAIL] lazy.nvim not found ($lazy_path missing)"
        failed=1
    fi
    return $failed
}

install_vim_plugins() {
    echo "[STEP] Installing Vim & Neovim plugins..."

    # Install vim-plug if not already installed
    local vim_plug_path="$HOME/.vim/autoload/plug.vim"
    if [ ! -f "$vim_plug_path" ]; then
        echo "[INFO] Installing vim-plug..."
        curl -fLo "$vim_plug_path" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        echo "[OK] vim-plug installed"
    else
        echo "[SKIP] vim-plug already installed"
    fi

    # Install Vim plugins. Errors used to go to /dev/null with an unconditional
    # "[OK]" after them, which is how a Debian box reported a clean install
    # while nvim 0.7.2 was aborting init.lua and installing no plugins at all.
    echo "[INFO] Installing Vim plugins..."
    if vim +PlugInstall +qall; then
        echo "[OK] Vim plugins installed"
    else
        echo "[WARN] Vim plugin install failed — run 'vim +PlugInstall +qall' to see why"
    fi

    # Install Neovim plugins (lazy.nvim bootstraps itself on first run)
    echo "[INFO] Installing Neovim plugins..."
    if nvim --headless "+Lazy! sync" +qa; then
        echo "[OK] Neovim plugins installed"
    else
        echo "[WARN] Neovim plugin install failed — run 'nvim --headless \"+Lazy! sync\" +qa' to see why"
    fi
}
