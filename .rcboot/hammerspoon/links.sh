#!/usr/bin/env bash
# Links: hammerspoon. macOS only; carries the translation popup.

_links_hammerspoon() {
    local d="${DOTFILES_DIR:-$HOME/.rc}"
    if [ -d "$d/hammerspoon" ] && [ "$(uname)" = "Darwin" ]; then
        echo "hammerspoon|dir|$d/hammerspoon|$HOME/.hammerspoon"
    fi
}
RC_LINK_SOURCES+=(_links_hammerspoon)
