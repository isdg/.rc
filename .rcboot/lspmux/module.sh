#!/usr/bin/env bash
# Module: lspmux — one rust-analyzer per workspace that outlives the editor.

[ "$RC_OS" = darwin ] || return 0

link lspmux/config.toml \
    "$HOME/Library/Application Support/lspmux/config.toml"

# `lspmux status` connects to the server, so it proves it is reachable rather
# than merely registered with launchd.
ensure_lspmux() {
    if lspmux status > /dev/null 2>&1; then
        echo "[OK] lspmux server running"
    else
        echo "[FAIL] lspmux server not running (brew services start lspmux)"
        return 1
    fi
}

# The server reads its config only at startup.
start_lspmux() {
    if ! command -v lspmux > /dev/null 2>&1; then
        echo "[SKIP] lspmux not installed"
    elif _link_changed lspmux/config.toml; then
        brew services restart lspmux
    elif ! lspmux status > /dev/null 2>&1; then
        brew services start lspmux
    fi
}
hook start_lspmux ensure_lspmux
