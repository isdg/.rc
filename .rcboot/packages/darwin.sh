#!/usr/bin/env bash
# Component: Package installation (Darwin)

# darwin/Brewfile cuts itself to the bootstrap level, read from
# HOMEBREW_RC_LEVEL: brew drops every variable without that prefix.
_bundle() {
    HOMEBREW_RC_LEVEL="$RC_LEVEL" \
        brew bundle "$@" --file="$DOTFILES_DIR/darwin/Brewfile"
}

ensure_packages_darwin() {
    echo "[STEP] Verifying packages (Brewfile, level $RC_LEVEL)..."
    if _bundle check > /dev/null 2>&1; then
        echo "[OK] All Brewfile packages installed"
    else
        echo "[FAIL] Some Brewfile packages are missing:"
        _bundle check 2>&1 | grep -v "^Using" || true
        return 1
    fi
}

install_packages_darwin() {
    echo "[STEP] Installing required packages (Brewfile, level $RC_LEVEL)..."

    # Update Homebrew (ignore errors from broken casks)
    brew update || echo "[WARN] brew update had warnings, continuing..."

    # || true so link/cask failures (e.g. MacVim conflicts) don't abort bootstrap
    _bundle || true

    echo "[OK] Packages installed"
}
