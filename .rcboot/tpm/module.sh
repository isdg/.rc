#!/usr/bin/env bash
# Module: tpm — TPM, the tmux plugins it loads (resurrect, omni, orchbus),
# their keys, and the omni and orchbus binaries.

fragment tmux/rc.d/07-plugins.conf
fragment tmux/rc.d/08-tpm.conf
fragment tmux/rc.d/09-omni.conf
fragment tmux/rc.d/14-orchbus.conf
fragment zsh/rc.d/18-omni.zsh

ensure_tpm() {
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "[OK] TPM installed"
    else
        echo "[FAIL] TPM not installed (~/.tmux/plugins/tpm missing)"
        return 1
    fi
}

install_tpm() {
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "[STEP] Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        echo "[OK] TPM installed. In tmux, press prefix + I to install plugins."
    else
        echo "[SKIP] TPM already installed"
    fi
}
hook install_tpm ensure_tpm

source "$RC_BOOT/tpm/plugins.sh"
step install_tmux_plugins ensure_tmux_plugins
