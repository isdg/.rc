#!/usr/bin/env bash
#
# Bootstrap script for Darwin systems
# Assembles modular components for dotfiles setup
#
# Usage:
#   ./darwin.sh                     — install / configure everything
#   ./darwin.sh --minimal           — install the tmux + nvim + zsh core only
#   ./darwin.sh --ensure            — verify everything is in place (no changes)
#   ./darwin.sh --ensure --minimal  — verify just the core
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
export DOTFILES_DIR

source "$SCRIPT_DIR/lib.sh"

# ── Arguments ──────────────────────────────────────────────────────────────────
MODE=install
BOOTSTRAP_MINIMAL=0
for arg in "$@"; do
    case "$arg" in
        --ensure)          MODE=ensure ;;
        --minimal|--core)  BOOTSTRAP_MINIMAL=1 ;;
        -h|--help)
            sed -n '3,11p' "${BASH_SOURCE[0]}" | sed 's/^#\{1,\} \{0,1\}//'
            exit 0
            ;;
        *)
            echo "[ERROR] unknown option: $arg (try --help)" >&2
            exit 2
            ;;
    esac
done
export BOOTSTRAP_MINIMAL
RC_MODE=$MODE
if [ "$BOOTSTRAP_MINIMAL" = "1" ]; then LEVEL=2; else LEVEL=3; fi

_profile_name() {
    if [ "$BOOTSTRAP_MINIMAL" = "1" ]; then echo "minimal (core only)"; else echo "full"; fi
}

# ── Ensure mode ────────────────────────────────────────────────────────────────
if [ "$MODE" = ensure ]; then
    echo "=========================================="
    echo "  Dotfiles Verify for Darwin"
    echo "  Profile: $(_profile_name)"
    echo "=========================================="
    echo ""

    set +e  # collect all failures instead of stopping at first
    run_modules "$LEVEL"
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
echo "  Profile: $(_profile_name)"
echo "=========================================="
echo ""

run_modules "$LEVEL"

echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Open Vim and verify plugins loaded correctly"
if [ "$BOOTSTRAP_MINIMAL" = "1" ]; then
    echo ""
    echo "Minimal profile: no language toolchains, so mason has no LSP servers to"
    echo "install, and plc/hr/omni/orchbus were skipped (they need cargo)."
    echo "Run ./.rcboot/darwin.sh for the full set."
fi
echo ""
