#!/usr/bin/env bash
# Component: GUI apps via Homebrew cask (Darwin only)
#
# GUI apps live here rather than in darwin/Brewfile, which is CLI-only and has
# no cask lines at all.

# One `App Name|cask|first-run note` line per app. install and ensure both read
# this one list, so they cannot drift apart, and adding an app is one line
# rather than an edit in two functions.
#
# The app name is the bundle in /Applications, which is not always the cask
# token, so both are spelled out. The note is optional and printed only when the
# app was actually installed just now.
_gui_apps_darwin() {
    echo "Ghostty|ghostty|"

    # Hammerspoon runs hammerspoon/init.lua -- the ⌘⌃T translate popup, the
    # screenshot-to-clipboard watcher, and the ⌘⇧J scroll mode. bootstrap has
    # always symlinked ~/.hammerspoon to that config, but nothing ever installed
    # the app that reads it, so the link verified [OK] while every feature in it
    # was dead. The cask also puts the `hs` CLI on PATH, which init.lua's
    # hs.ipc needs.
    echo "Hammerspoon|hammerspoon|Launch it once and grant Accessibility (System Settings > Privacy & Security > Accessibility) -- the hotkeys post events and stay dead without it"

    # Deliberately not here: Homerow. hammerspoon/scroll.lua does the scrolling
    # it was installed for, in Lua we control and with no licence -- see the
    # header there.
}

_app_installed() {
    [ -d "/Applications/$1.app" ]
}

ensure_gui_apps_darwin() {
    echo "[STEP] Verifying GUI apps..."
    local failed=0

    while IFS='|' read -r app cask _note; do
        [ -z "$app" ] && continue
        if _app_installed "$app"; then
            echo "[OK] $app"
        else
            echo "[FAIL] $app not installed (brew install --cask $cask)"
            failed=1
        fi
    done < <(_gui_apps_darwin)

    return $failed
}

install_gui_apps_darwin() {
    echo "[STEP] Installing GUI apps..."

    while IFS='|' read -r app cask note; do
        [ -z "$app" ] && continue
        if _app_installed "$app"; then
            echo "[SKIP] $app already installed"
        elif brew install --cask "$cask"; then
            echo "[OK] Installed $app"
            # A plain `[ -n "$note" ] && echo ...` would leave the loop with a
            # nonzero status on the no-note case. Exempt from set -e by the
            # AND-list rule, but not worth resting an install run on it.
            if [ -n "$note" ]; then
                echo "[INFO] $note"
            fi
        else
            echo "[WARN] $app installation failed, continuing..."
        fi
    done < <(_gui_apps_darwin)

    echo "[OK] GUI apps installed"
}
