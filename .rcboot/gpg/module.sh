#!/usr/bin/env bash
# Module: gpg-agent.

# Darwin only: the pinentry-program line in it is an absolute /opt/homebrew
# path, which would wedge the agent on Linux. Only this file is linked, never
# ~/.gnupg itself -- keyring, trustdb and sockets do not belong in a repo.
if [ "$RC_OS" = darwin ]; then
    link gpg/gpg-agent.conf "$HOME/.gnupg/gpg-agent.conf"
fi

# _relink's `mkdir -p` makes ~/.gnupg 0755, and gpg prints "unsafe permissions
# on homedir" on every invocation until it is 0700.
secure_gnupg_dir() {
    if [ -d "$HOME/.gnupg" ]; then
        chmod 700 "$HOME/.gnupg"
    fi
}
hook secure_gnupg_dir
