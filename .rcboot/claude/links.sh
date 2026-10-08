#!/usr/bin/env bash
# Links: Claude Code settings and the status line script.

_links_claude() {
    local d="${DOTFILES_DIR:-$HOME/.rc}" f

    # settings.json.local is the per-machine override and stays out of the repo.
    # statusline-command.sh is linked because settings.json names it by path.
    for f in settings.json statusline-command.sh; do
        if [ -f "$d/claude/$f" ]; then
            echo "claude/$f|file|$d/claude/$f|$HOME/.claude/$f"
        fi
    done
}
RC_LINK_SOURCES+=(_links_claude)
