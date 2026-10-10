#!/usr/bin/env bash
#
# Bootstrap script for Darwin systems
# Assembles modular components for dotfiles setup
#
# Usage:
#   ./darwin.sh             — install / configure everything (level 3)
#   ./darwin.sh --level=N   — up to level N; fragments above it are switched off
#   ./darwin.sh --minimal   — the same as --level=2
#   ./darwin.sh --ensure    — verify, with or without --level (no changes)
#
# Levels (.rcboot/modules): 0 bare, 1 core (zsh, tmux, vim, git), 2 tools
# (fzf, zoxide, delta, bat, tig), 3 full (nvim, plugins, GUI apps, toolchains).
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
export DOTFILES_DIR

source "$SCRIPT_DIR/lib.sh"

parse_args "$@"

# ── Ensure mode ────────────────────────────────────────────────────────────────
if [ "$RC_MODE" = ensure ]; then
    echo "=========================================="
    echo "  Dotfiles Verify for Darwin"
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
echo "  Dotfiles Bootstrap for Darwin"
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
if [ "$RC_LEVEL" -lt 3 ]; then
    echo ""
    echo "Level $RC_LEVEL: no nvim plugins, vim plugins, tmux plugins, language"
    echo "toolchains or side tools. Run ./.rcboot/darwin.sh for the full set."
fi
echo ""
