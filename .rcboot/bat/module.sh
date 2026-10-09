#!/usr/bin/env bash
# Module: bat — the config dir, which carries the vs_dark/vs_light themes.

link bat "$HOME/.config/bat"

# bat reads its themes out of ~/.config/bat, but only after its cache is
# rebuilt — without this BAT_THEME=vs_dark / vs_light does not resolve. Only
# when the link actually changed: on a settled machine there is nothing new.
build_bat_cache() {
    if _link_changed bat && command -v bat >/dev/null 2>&1; then
        bat cache --build >/dev/null 2>&1 && echo "[OK] Rebuilt bat theme cache"
    fi
    return 0
}
hook build_bat_cache

# Linux: newer bat and delta than the distro ships. After the link: it needs
# ~/.config/bat/themes to exist before it can test and build the theme cache.
if [ "$RC_OS" = linux ]; then
    source "$RC_BOOT/bat/pagers_linux.sh"
    step install_pagers_linux ensure_pagers_linux
fi
