#!/usr/bin/env bash
#
# Bootstrap script for Linux systems
# Assembles modular components for dotfiles setup
#
# Usage:
#   ./linux.sh             — install / configure everything (level 3)
#   ./linux.sh --level=N   — up to level N; fragments above it are switched off
#   ./linux.sh --ensure    — verify, with or without --level (no changes)
#
# Levels (.rcboot/modules): 0 bare (~/.zshrc.local), 1 core (zsh, tmux, vim,
# git), 2 tools (fzf, zoxide, delta, bat, tig), 3 full (nvim, plugins, GUI
# apps, toolchains).
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
export DOTFILES_DIR

# Everything this script installs because the distro's own copy is too old —
# neovim, bat, delta — lands in ~/.local/bin, which only .zshrc puts on PATH.
# This script runs under bash, so without this line both the install steps and
# every --ensure check measure the older /usr/bin copy and report a failure on
# a machine that is actually fine.
export PATH="$HOME/.local/bin:$HOME/.elan/bin:$PATH"

source "$SCRIPT_DIR/lib.sh"
parse_args "$@"

# ── Ensure mode ────────────────────────────────────────────────────────────────
if [ "$RC_MODE" = ensure ]; then
    echo "=========================================="
    echo "  Dotfiles Verify for Linux"
    echo "  Level: $RC_LEVEL"
    echo "=========================================="
    echo ""

    set +e  # collect all failures instead of stopping at first
    run_modules "$RC_LEVEL"
    FAILURES=$RC_FAILURES

    echo "=========================================="
    if [ "$FAILURES" -eq 0 ]; then
        echo "  All checks passed!"
    else
        echo "  $FAILURES check(s) failed!"
    fi
    echo "=========================================="
    exit "$FAILURES"
fi

# ── Install mode ───────────────────────────────────────────────────────────────
echo "=========================================="
echo "  Dotfiles Bootstrap for Linux"
echo "  Level: $RC_LEVEL"
echo "=========================================="
echo ""

run_modules "$RC_LEVEL"

echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Open Vim and verify plugins loaded correctly"
echo ""
