#!/usr/bin/env bash
# Links: bat — the config dir, which carries the vs_dark/vs_light themes.

_links_bat() {
    local d="${DOTFILES_DIR:-$HOME/.rc}"
    if [ -d "$d/bat" ]; then
        echo "bat config|dir|$d/bat|$HOME/.config/bat"
    fi
}
RC_LINK_SOURCES+=(_links_bat)

# bat reads its themes out of ~/.config/bat, but only after its cache is
# rebuilt — without this BAT_THEME=vs_dark / vs_light does not resolve. Only
# when the link actually changed: on a settled machine there is nothing new.
build_bat_cache() {
    if _link_changed "bat config" && command -v bat >/dev/null 2>&1; then
        bat cache --build >/dev/null 2>&1 && echo "[OK] Rebuilt bat theme cache"
    fi
    return 0
}
RC_LINK_HOOKS+=("build_bat_cache|")
