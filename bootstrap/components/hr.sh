#!/usr/bin/env bash
# Component: hr — text reading manager binary (shared)
#
# Clones the hr repo if needed and installs the binary via go install into
# ~/go/bin. The zsh reading-list wrapper (zsh/fzf.zsh: hrb) calls this binary.

HR_REPO="https://github.com/isdg/hr.git"
HR_SRC="$HOME/hr"

ensure_hr() {
    echo "[STEP] Verifying hr..."
    if command -v hr >/dev/null 2>&1; then
        echo "[OK] hr installed ($(command -v hr))"
        return 0
    fi
    echo "[FAIL] hr not found on PATH (expected ~/go/bin/hr)"
    return 1
}

install_hr() {
    echo "[STEP] Installing hr..."

    if ! command -v go >/dev/null 2>&1; then
        echo "[WARN] go not found — install Go first (Brewfile: brew \"go\"). Skipping hr."
        return 0
    fi

    if [ ! -d "$HR_SRC/.git" ]; then
        echo "[INFO] Cloning hr into $HR_SRC..."
        git clone "$HR_REPO" "$HR_SRC" || {
            echo "[WARN] git clone failed — skipping hr."
            return 0
        }
    else
        echo "[INFO] hr source already present at $HR_SRC — pulling latest..."
        git -C "$HR_SRC" pull --ff-only || echo "[WARN] git pull hr failed — building existing checkout as-is."
    fi

    echo "[INFO] go install (in $HR_SRC)..."
    if (cd "$HR_SRC" && go install .); then
        echo "[OK] hr installed to ~/go/bin/hr"
    else
        echo "[WARN] go install failed — see output above."
    fi
    return 0
}
