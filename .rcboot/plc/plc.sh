#!/usr/bin/env bash
# Component: plc — palace notes manager binaries (shared)
#
# Clones the plc repo if needed and installs its binaries via cargo into
# ~/.cargo/bin: plc, which the zsh palace wrappers (zsh/palace.zsh) call,
# and plc-lsp, which nvim starts on vault notes (nvim/lua/plugins/lsp.lua).

PLC_REPO="https://github.com/isdg/plc.git"
PLC_SRC="$HOME/plc"
PLC_BINS=(plc plc-lsp)

ensure_plc() {
    echo "[STEP] Verifying plc..."
    local bin status=0
    for bin in "${PLC_BINS[@]}"; do
        if command -v "$bin" >/dev/null 2>&1; then
            echo "[OK] $bin installed ($(command -v "$bin"))"
        else
            echo "[FAIL] $bin not found on PATH (expected ~/.cargo/bin/$bin)"
            status=1
        fi
    done
    return "$status"
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

    _export_buildable_sdk

    local bin
    for bin in "${PLC_BINS[@]}"; do
        echo "[INFO] cargo install --path $PLC_SRC/$bin..."
        if cargo install --path "$PLC_SRC/$bin"; then
            echo "[OK] $bin installed to ~/.cargo/bin/$bin"
        else
            echo "[WARN] cargo install $bin failed — see output above."
        fi
    done
    return 0
}
