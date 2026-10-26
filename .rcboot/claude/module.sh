#!/usr/bin/env bash
# Module: Claude Code instructions, settings, status line and hooks.

# settings.json.local is the per-machine override and stays out of the repo.
# The scripts are linked because settings.json names them by path.
local f
for f in CLAUDE.md settings.json statusline-command.sh \
    hooks/worktree.sh; do
    link "claude/$f" "$HOME/.claude/$f"
done

# Each rule is linked on its own, so ~/.claude/rules stays a real directory
# that can also hold rules no branch tracks.
for f in "$DOTFILES_DIR"/claude/rules/*.md; do
    [ -e "$f" ] || continue
    link "claude/rules/${f##*/}" "$HOME/.claude/rules/${f##*/}"
done
