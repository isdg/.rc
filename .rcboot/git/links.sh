#!/usr/bin/env bash
# Links: git.

_links_git() {
    local d="${DOTFILES_DIR:-$HOME/.rc}"
    echo ".gitconfig|file|$d/git/.gitconfig|$HOME/.gitconfig"
}
RC_LINK_SOURCES+=(_links_git)
