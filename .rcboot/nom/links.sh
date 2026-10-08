#!/usr/bin/env bash
# Links: nom (RSS reader). Darwin uses Library/Application Support, Linux XDG.

_links_nom() {
    local d="${DOTFILES_DIR:-$HOME/.rc}" dir
    [ -f "$d/nom/config.yml" ] || return 0
    if [ "$(uname)" = "Darwin" ]; then
        dir="$HOME/Library/Application Support/nom"
    else
        dir="${XDG_CONFIG_HOME:-$HOME/.config}/nom"
    fi
    echo "nom config.yml|file|$d/nom/config.yml|$dir/config.yml"
}
RC_LINK_SOURCES+=(_links_nom)
