#!/usr/bin/env bash
# Component: plc — palace notes manager binary (shared)
#
# Clones the plc repo if needed and installs the binary via cargo into
# ~/.cargo/bin. The zsh palace wrappers (zsh/palace.zsh) call this binary.

PLC_REPO="https://github.com/isaigordeev/plc.git"
PLC_SRC="$HOME/plc"

ensure_plc() {
    echo "[STEP] Verifying plc..."
    if command -v plc >/dev/null 2>&1; then
        echo "[OK] plc installed ($(command -v plc))"
        return 0
    fi
    echo "[FAIL] plc not found on PATH (expected ~/.cargo/bin/plc)"
    return 1
}

install_plc() {
    echo "[STEP] Installing plc..."

    if ! command -v cargo >/dev/null 2>&1; then
        echo "[WARN] cargo not found — install rust first (Brewfile: brew \"rust\"). Skipping plc."
        return 0
    fi

    if [ ! -d "$PLC_SRC/.git" ]; then
        echo "[INFO] Cloning plc into $PLC_SRC..."
        git clone "$PLC_REPO" "$PLC_SRC" || {
            echo "[WARN] git clone failed — skipping plc."
            return 0
        }
    else
        echo "[INFO] plc source already present at $PLC_SRC — pulling latest..."
        git -C "$PLC_SRC" pull --ff-only || echo "[WARN] git pull plc failed — building existing checkout as-is."
    fi

    echo "[INFO] cargo install --path $PLC_SRC/plc..."
    if cargo install --path "$PLC_SRC/plc"; then
        echo "[OK] plc installed to ~/.cargo/bin/plc"
    else
        echo "[WARN] cargo install failed — see output above."
    fi
    return 0
}
