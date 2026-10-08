#!/usr/bin/env bash
# Links: gpg-agent.

# Darwin only: the pinentry-program line in it is an absolute /opt/homebrew
# path, which would wedge the agent on Linux. Only this file is linked, never
# ~/.gnupg itself -- keyring, trustdb and sockets do not belong in a repo.
_links_gpg() {
    local conf="${DOTFILES_DIR:-$HOME/.rc}/gpg/gpg-agent.conf"
    if [ -f "$conf" ] && [ "$(uname)" = "Darwin" ]; then
        echo "gpg-agent.conf|file|$conf|$HOME/.gnupg/gpg-agent.conf"
    fi
}
RC_LINK_SOURCES+=(_links_gpg)

# _relink's `mkdir -p` makes ~/.gnupg 0755, and gpg prints "unsafe permissions
# on homedir" on every invocation until it is 0700.
secure_gnupg_dir() {
    if [ -d "$HOME/.gnupg" ]; then
        chmod 700 "$HOME/.gnupg"
    fi
}
RC_LINK_HOOKS+=("secure_gnupg_dir|")
