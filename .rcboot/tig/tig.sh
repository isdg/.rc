#!/usr/bin/env bash
# Component: Tig config (shared)

# The binary, not just the rc file. Checking only the symlink reported a
# clean "[OK] Linked .tigrc" on a box with no tig installed at all.
ensure_tig() {
    echo "[STEP] Verifying tig..."
    if command -v tig > /dev/null 2>&1; then
        echo "[OK] tig installed ($(command -v tig))"
    else
        echo "[FAIL] tig not installed"
        return 1
    fi
}
