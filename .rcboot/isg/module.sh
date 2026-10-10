#!/usr/bin/env bash
# Module: isg — ~/.config/isg, this machine's own state, never in a repo:
# theme (light|dark, read by every tool, flipped by sh/toggle_theme.sh) and
# machine_id (~/.rcstate's per-machine slot). Created once, then left alone.

RC_ISG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/isg"

install_isg_state() {
    mkdir -p "$RC_ISG_DIR"
    if [ ! -f "$RC_ISG_DIR/theme" ]; then
        echo light > "$RC_ISG_DIR/theme"
        echo "[OK] Seeded $RC_ISG_DIR/theme = light"
    fi
    # Same shape as ~/.rcstate/sync.sh makes, so either may create it first.
    if [ ! -f "$RC_ISG_DIR/machine_id" ]; then
        od -An -tx1 -N4 /dev/urandom | tr -d ' \n' > "$RC_ISG_DIR/machine_id"
        echo "[OK] Created $RC_ISG_DIR/machine_id"
    fi
}

ensure_isg_state() {
    local rc=0 mode
    mode="$(cat "$RC_ISG_DIR/theme" 2>/dev/null)"
    case "$mode" in
        light|dark) echo "[OK] Theme mode: $mode" ;;
        *) echo "[FAIL] $RC_ISG_DIR/theme is not light or dark"; rc=1 ;;
    esac
    if [ -s "$RC_ISG_DIR/machine_id" ]; then
        echo "[OK] Machine id: $(cat "$RC_ISG_DIR/machine_id")"
    else
        echo "[FAIL] $RC_ISG_DIR/machine_id is missing"
        rc=1
    fi
    return "$rc"
}

step install_isg_state ensure_isg_state
