#!/usr/bin/env bash
# Component: oui — the typing test binary (shared)
#
# Clones the oui repo if needed and installs the binary via cargo into
# ~/.cargo/bin. Its config is oui/.ouirc, linked by module.sh; its history
# lives in ~/.oui and is snapshotted by ~/.rcstate/sync.sh, not tracked here.

# SSH, not HTTPS: the repo is private, and gh is set up for ssh.
OUI_REPO="git@github.com:isdg/oui.git"
OUI_SRC="$HOME/oui"

ensure_oui() {
    echo "[STEP] Verifying oui..."
    if command -v oui >/dev/null 2>&1; then
        echo "[OK] oui installed ($(command -v oui))"
        return 0
    fi
    echo "[FAIL] oui not found on PATH (expected ~/.cargo/bin/oui)"
    return 1
}

install_oui() {
    echo "[STEP] Installing oui..."

    if ! command -v cargo >/dev/null 2>&1; then
        echo "[WARN] cargo not found — install rust first (Brewfile: brew \"rust\"). Skipping oui."
        return 0
    fi

    if [ ! -d "$OUI_SRC/.git" ]; then
        echo "[INFO] Cloning oui into $OUI_SRC..."
        git clone "$OUI_REPO" "$OUI_SRC" || {
            echo "[WARN] git clone failed — skipping oui."
            return 0
        }
    else
        echo "[INFO] oui source already present at $OUI_SRC — pulling latest..."
        git -C "$OUI_SRC" pull --ff-only || echo "[WARN] git pull oui failed — building existing checkout as-is."
    fi

    _export_buildable_sdk

    echo "[INFO] cargo install --path $OUI_SRC..."
    if cargo install --path "$OUI_SRC"; then
        echo "[OK] oui installed to ~/.cargo/bin/oui"
    else
        echo "[WARN] cargo install failed — see output above."
    fi
    return 0
}
