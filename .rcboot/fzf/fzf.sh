#!/usr/bin/env bash
# Component: fzf keybindings (shared)

ensure_fzf_darwin() {
    echo "[STEP] Verifying fzf keybindings..."
    if [ -f "$HOME/.fzf.zsh" ]; then
        echo "[OK] fzf keybindings installed (~/.fzf.zsh)"
    else
        echo "[FAIL] fzf keybindings not installed (~/.fzf.zsh missing)"
        return 1
    fi
}

ensure_fzf_linux() {
    echo "[STEP] Verifying fzf..."
    local failed=0
    if [ -d "$HOME/.fzf" ]; then
        echo "[OK] fzf installed (~/.fzf)"
    else
        echo "[FAIL] fzf not installed (~/.fzf missing)"
        failed=1
    fi
    # The shell integration is the part that actually binds ^R, and it is
    # written by ~/.fzf/install — a bare clone is not enough.
    if [ -f "$HOME/.fzf.zsh" ]; then
        echo "[OK] fzf shell integration installed (~/.fzf.zsh)"
    else
        echo "[FAIL] fzf shell integration missing (~/.fzf.zsh) — ^R will not open history"
        failed=1
    fi
    return $failed
}

install_fzf_darwin() {
    echo "[STEP] Installing fzf keybindings..."

    local fzf_install
    fzf_install="$(brew --prefix 2>/dev/null)/opt/fzf/install"

    if [ -f "$fzf_install" ]; then
        if "$fzf_install" --key-bindings --completion --no-update-rc --no-bash --no-fish; then
            echo "[OK] fzf keybindings installed"
        else
            echo "[WARN] fzf keybindings had issues, continuing..."
        fi
    else
        echo "[SKIP] fzf install script not found"
    fi
}

install_fzf_linux() {
    echo "[STEP] Setting up fzf keybindings..."

    # We install fzf from source even when the distro packages it: this config
    # needs fzf >= 0.48 for $FZF_DEFAULT_OPTS_FILE (see zsh/.zshenv — it is what
    # themes every picker) and for `fzf --zsh`, and Debian bookworm ships 0.38.
    if [ ! -d "$HOME/.fzf" ]; then
        echo "[INFO] Installing fzf from source..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    else
        echo "[SKIP] fzf clone already present"
    fi

    # Keyed on ~/.fzf.zsh, not on the clone: the old check skipped this whenever
    # the directory existed, so a clone whose install step had failed never got
    # a second chance and ^R stayed dead forever.
    if [ ! -f "$HOME/.fzf.zsh" ]; then
        echo "[INFO] Writing fzf shell integration (~/.fzf.zsh)..."
        "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish \
            || echo "[WARN] fzf install had issues"
    else
        echo "[SKIP] fzf shell integration already written"
    fi

    # ~/.fzf.zsh runs `fzf --zsh`, which resolves through PATH. fzf's own
    # installer *appends* ~/.fzf/bin, so on Debian /usr/bin/fzf 0.38 wins and
    # that line fails with "unknown option: --zsh" — leaving ^R bound to
    # redisplay and $FZF_DEFAULT_OPTS_FILE ignored. .zshrc prepends ~/.fzf/bin
    # to fix the order; warn here so the mismatch is visible at install time.
    if command -v fzf > /dev/null 2>&1 && [ -x "$HOME/.fzf/bin/fzf" ]; then
        local system_fzf; system_fzf="$(command -v fzf)"
        if [ "$system_fzf" != "$HOME/.fzf/bin/fzf" ]; then
            echo "[INFO] $system_fzf ($(fzf --version 2>/dev/null | cut -d' ' -f1)) shadows ~/.fzf/bin/fzf ($("$HOME/.fzf/bin/fzf" --version | cut -d' ' -f1)) — .zshrc puts ~/.fzf/bin first"
        fi
    fi

    echo "[OK] fzf ready"
}
