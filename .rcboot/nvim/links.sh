#!/usr/bin/env bash
# Links: neovim.

_links_nvim() {
    local d="${DOTFILES_DIR:-$HOME/.rc}"
    echo "nvim config|dir|$d/nvim|$HOME/.config/nvim"
}
RC_LINK_SOURCES+=(_links_nvim)
