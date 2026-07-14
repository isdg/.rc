#!/usr/bin/env bash
# Component: GUI apps via Homebrew cask (Darwin only)

# Check if a cask app is installed (by app name in /Applications)
_app_installed() {
    [ -d "/Applications/$1.app" ]
}

ensure_gui_apps_darwin() {
    echo "[STEP] Verifying GUI apps..."
    local failed=0
    local apps=("Visual Studio Code" "Ghostty" "Homerow")
    for app in "${apps[@]}"; do
        if _app_installed "$app"; then
            echo "[OK] $app"
        else
            echo "[FAIL] $app not installed (/Applications/$app.app missing)"
            failed=1
        fi
    done
    return $failed
}

install_gui_apps_darwin() {
    echo "[STEP] Installing GUI apps..."

    if _app_installed "Visual Studio Code"; then
        echo "[SKIP] VSCode already installed"
    else
        brew install --cask visual-studio-code || echo "[WARN] VSCode installation failed"
    fi

    if _app_installed "Ghostty"; then
        echo "[SKIP] Ghostty already installed"
    else
        brew install --cask ghostty || echo "[WARN] Ghostty installation failed"
    fi

    if _app_installed "Homerow"; then
        echo "[SKIP] Homerow already installed"
    else
        brew install --cask homerow || echo "[WARN] Homerow installation failed"
    fi

    echo "[OK] GUI apps installed"
}
