#!/usr/bin/env bash
# Module: tmux — .tmux.conf and its plugin-free fragments, then a reload of
# any running server. tpm adds the plugins.

link tmux/.tmux.conf "$HOME/.tmux.conf"
fragment tmux/rc.d/00-options.conf
fragment tmux/rc.d/01-aliases.conf
fragment tmux/rc.d/02-keys.conf
fragment tmux/rc.d/03-copy-mode.conf
fragment tmux/rc.d/04-status.conf
fragment tmux/rc.d/05-theme.conf
fragment tmux/rc.d/10-layer.conf
fragment tmux/rc.d/11-pane-save.conf
fragment tmux/rc.d/12-alerts.conf
fragment tmux/rc.d/13-splits.conf
fragment tmux/rc.d/15-russian.conf

setup_tmux() {
    # Apply to any already-running tmux server. Unlike ghostty/k9s, tmux's
    # config reads the theme mode file directly at parse time (see the
    # run-shell block in tmux/rc.d/05-theme.conf), so there's no "active"
    # symlink to seed here — just re-source so an existing session reflects it
    # now instead of only on the next `tmux new`.
    if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
        tmux source-file "$HOME/.tmux.conf" && echo "[OK] Reloaded tmux config for running server"
    fi
}
finally setup_tmux
