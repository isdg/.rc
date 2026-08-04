#!/usr/bin/env bash
# Component: Package installation (Darwin)
#
# Which Brewfile is used depends on the profile darwin.sh selected:
#   full     (default)   darwin/Brewfile          — everything
#   minimal  (--minimal) darwin/Brewfile.minimal  — tmux + nvim + zsh core only

_brewfile_path() {
    if [ "${BOOTSTRAP_MINIMAL:-0}" = "1" ]; then
        echo "$DOTFILES_DIR/darwin/Brewfile.minimal"
    else
        echo "$DOTFILES_DIR/darwin/Brewfile"
    fi
}

ensure_packages_darwin() {
    local brewfile
    brewfile="$(_brewfile_path)"
    echo "[STEP] Verifying packages ($(basename "$brewfile"))..."
    if [ ! -f "$brewfile" ]; then
        echo "[FAIL] Brewfile not found at $brewfile"
        return 1
    fi
    if brew bundle check --file="$brewfile" > /dev/null 2>&1; then
        echo "[OK] All Brewfile packages installed"
    else
        echo "[FAIL] Some Brewfile packages are missing:"
        brew bundle check --file="$brewfile" 2>&1 | grep -v "^Using" || true
        return 1
    fi
}

install_packages_darwin() {
    local brewfile
    brewfile="$(_brewfile_path)"
    echo "[STEP] Installing required packages ($(basename "$brewfile"))..."

    # Update Homebrew (ignore errors from broken casks)
    brew update || echo "[WARN] brew update had warnings, continuing..."

    if [ ! -f "$brewfile" ]; then
        echo "[ERROR] Brewfile not found at $brewfile"
        return 1
    fi

    # || true so link/cask failures (e.g. MacVim conflicts) don't abort bootstrap
    brew bundle --file="$brewfile" || true

    echo "[OK] Packages installed"
}
