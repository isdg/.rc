#!/usr/bin/env bash
# Module: tmux — .tmux.conf and its rc.d/, then TPM and a reload of any
# running server.

link tmux/.tmux.conf "$HOME/.tmux.conf"
fragment tmux/rc.d/00-options.conf
fragment tmux/rc.d/01-aliases.conf
fragment tmux/rc.d/02-keys.conf
fragment tmux/rc.d/03-copy-mode.conf
fragment tmux/rc.d/04-status.conf
fragment tmux/rc.d/05-theme.conf
fragment tmux/rc.d/06-fzf-env.conf
fragment tmux/rc.d/07-plugins.conf
fragment tmux/rc.d/08-tpm.conf
fragment tmux/rc.d/09-omni.conf
fragment tmux/rc.d/10-layer.conf
fragment tmux/rc.d/11-pane-save.conf
fragment tmux/rc.d/12-alerts.conf
fragment tmux/rc.d/13-splits.conf
fragment tmux/rc.d/14-orchbus.conf
fragment tmux/rc.d/15-russian.conf

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
