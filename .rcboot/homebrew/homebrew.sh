#!/usr/bin/env bash
# Component: Homebrew (Darwin only)

ensure_homebrew() {
    if command -v brew > /dev/null 2>&1; then
        echo "[OK] Homebrew installed ($(brew --version | head -1))"
    else
        echo "[FAIL] Homebrew not installed"
        return 1
    fi
}

install_homebrew() {
    echo "[STEP] Checking Homebrew..."

    if ! command -v brew > /dev/null 2>&1; then
        echo "[INFO] Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo "[INFO] Configuring Homebrew for Apple Silicon..."
            if ! grep -q '/opt/homebrew/bin/brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            fi
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        echo "[OK] Homebrew installed"
    else
        echo "[SKIP] Homebrew already installed"
    fi
}
