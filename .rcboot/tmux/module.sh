#!/usr/bin/env bash
# Module: tmux — .tmux.conf and its rc.d/, then TPM and a reload of any
# running server.

link tmux/.tmux.conf "$HOME/.tmux.conf"
# Literal ~/.config, not $XDG_CONFIG_HOME: .tmux.conf and tpm both expand
# only ~ in the source-file path.
link tmux/rc.d "$HOME/.config/tmux/rc.d"

ensure_tpm() {
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "[OK] TPM installed"
    else
        echo "[FAIL] TPM not installed (~/.tmux/plugins/tpm missing)"
        return 1
    fi
}

setup_tmux() {
    # Apply to any already-running tmux server. Unlike ghostty/k9s, tmux's
    # config reads the theme mode file directly at parse time (see the
    # run-shell block in tmux/rc.d/05-theme.conf), so there's no "active"
    # symlink to seed here — just re-source so an existing session reflects it
    # now instead of only on the next `tmux new`.
    if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
        tmux source-file "$HOME/.tmux.conf" && echo "[OK] Reloaded tmux config for running server"
    fi

    # Install TPM (Tmux Plugin Manager)
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "[STEP] Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        echo "[OK] TPM installed. In tmux, press prefix + I to install plugins."
    else
        echo "[SKIP] TPM already installed"
    fi
}
hook setup_tmux ensure_tpm
