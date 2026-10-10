#!/usr/bin/env bash
# Module: Claude Code settings and the status line script.

# settings.json.local is the per-machine override and stays out of the repo.
# statusline-command.sh is linked because settings.json names it by path.
local f
for f in settings.json statusline-command.sh; do
    link "claude/$f" "$HOME/.claude/$f"
done
