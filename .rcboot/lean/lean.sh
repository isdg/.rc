#!/usr/bin/env bash
# Component: Lean 4 toolchain via elan (shared)
#
# elan is Lean's rustup: `lean` and `lake` are proxies that run whichever
# toolchain a project's lean-toolchain file pins. Darwin gets elan from the
# Brewfile (elan-init); Linux gets the upstream installer into ~/.elan/bin.

ELAN_INIT_URL="https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh"

ensure_lean() {
    echo "[STEP] Verifying Lean..."
    if ! command -v elan >/dev/null 2>&1; then
        echo "[FAIL] elan not found on PATH"
        return 1
    fi
    # The proxies exist as soon as elan does; only a default toolchain makes
    # them answer outside a project.
    if lean --version >/dev/null 2>&1 && lake --version >/dev/null 2>&1; then
        echo "[OK] $(lean --version | head -n1)"
        return 0
    fi
    echo "[FAIL] elan has no default toolchain (run: elan default stable)"
    return 1
}

install_lean() {
    echo "[STEP] Installing Lean..."

    if ! command -v elan >/dev/null 2>&1; then
        if [ "$(uname)" = "Darwin" ]; then
            echo "[WARN] elan not found — expected from the Brewfile (brew \"elan-init\"). Skipping Lean."
            return 0
        fi
        # .zshrc already puts ~/.elan/bin on PATH, so the installer must not
        # append its own line to the profile files.
        curl -sSfL "$ELAN_INIT_URL" \
            | sh -s -- -y --no-modify-path --default-toolchain stable \
            || { echo "[WARN] elan install failed — skipping Lean."; return 0; }
        export PATH="$HOME/.elan/bin:$PATH"
    fi

    if lean --version >/dev/null 2>&1; then
        echo "[SKIP] default toolchain already set ($(lean --version | head -n1))"
    elif elan default stable; then
        echo "[OK] $(lean --version | head -n1)"
    else
        echo "[WARN] elan default stable failed — see output above."
    fi
    return 0
}
