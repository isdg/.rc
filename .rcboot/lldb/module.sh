#!/usr/bin/env bash
# Module: lldb.

link lldb/.lldbinit "$HOME/.lldbinit"

ensure_lldb() {
    echo "[STEP] Verifying lldb..."
    if command -v lldb > /dev/null 2>&1; then
        echo "[OK] lldb installed ($(command -v lldb))"
    else
        echo "[FAIL] lldb not installed"
        return 1
    fi
}
step - ensure_lldb
