#!/usr/bin/env bash
#
# Bootstrap script for Darwin and Linux
# Assembles modular components for dotfiles setup
#
# Usage:
#   ./boot.sh             — install / configure everything (level 3)
#   ./boot.sh --level=N   — up to level N; fragments above it are switched off
#   ./boot.sh --ensure    — verify, with or without --level (no changes)
#
# Levels (.rcboot/modules): 0 bare (nothing yet), 1 core (zsh, tmux, vim,
# git), 2 tools (fzf, zoxide, delta, bat, tig), 3 full (nvim, plugins, GUI
# apps, toolchains). Modules branch on the OS themselves ($RC_OS).
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
export DOTFILES_DIR

source "$SCRIPT_DIR/lib.sh"
parse_args "$@"

case "$RC_OS" in
    darwin) OS_NAME=Darwin ;;
    linux)
        OS_NAME=Linux
        # Everything this script installs because the distro's own copy is too
        # old — neovim, bat, delta — lands in ~/.local/bin, which only .zshrc
        # puts on PATH. This script runs under bash, so without this line both
        # the install steps and every --ensure check measure the older /usr/bin
        # copy and report a failure on a machine that is actually fine.
        export PATH="$HOME/.local/bin:$HOME/.elan/bin:$PATH"
        ;;
esac

# ── Ensure mode ────────────────────────────────────────────────────────────────
if [ "$RC_MODE" = ensure ]; then
    echo "=========================================="
    echo "  Dotfiles Verify for $OS_NAME"
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
echo "  Dotfiles Bootstrap for $OS_NAME"
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
    echo "toolchains or side tools. Run ./.rcboot/boot.sh for the full set."
fi
echo ""
