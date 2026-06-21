#!/usr/bin/env bash
#
# Bootstrap script for Darwin (macOS) systems
# Assembles modular components for dotfiles setup
#
# Usage:
#   ./darwin.sh           — install / configure everything
#   ./darwin.sh --ensure  — verify everything is in place (no changes made)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
export DOTFILES_DIR

# Load components
source "$SCRIPT_DIR/components/helpers.sh"
source "$SCRIPT_DIR/components/homebrew.sh"
source "$SCRIPT_DIR/components/packages_darwin.sh"
source "$SCRIPT_DIR/components/gui_apps_darwin.sh"
source "$SCRIPT_DIR/components/ohmyzsh.sh"
source "$SCRIPT_DIR/components/directories.sh"
source "$SCRIPT_DIR/components/dotfiles.sh"
source "$SCRIPT_DIR/components/vscode.sh"
source "$SCRIPT_DIR/components/hyper.sh"
source "$SCRIPT_DIR/components/fonts.sh"
source "$SCRIPT_DIR/components/tig.sh"
source "$SCRIPT_DIR/components/vim.sh"
source "$SCRIPT_DIR/components/plc.sh"
source "$SCRIPT_DIR/components/fzf.sh"
source "$SCRIPT_DIR/components/shell.sh"
source "$SCRIPT_DIR/components/keyremap.sh"
source "$SCRIPT_DIR/components/darwin_defaults.sh"

# ── Ensure mode ────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--ensure" ]]; then
    echo "=========================================="
    echo "  Dotfiles Verify for Darwin"
    echo "=========================================="
    echo ""

    FAILURES=0
    set +e  # collect all failures instead of stopping at first

    ensure_homebrew             || FAILURES=$((FAILURES + 1)); echo ""
    ensure_packages_darwin      || FAILURES=$((FAILURES + 1)); echo ""
    ensure_gui_apps_darwin      || FAILURES=$((FAILURES + 1)); echo ""
    ensure_ohmyzsh              || FAILURES=$((FAILURES + 1)); echo ""
    ensure_directories          || FAILURES=$((FAILURES + 1)); echo ""
    ensure_dotfiles             || FAILURES=$((FAILURES + 1)); echo ""
    ensure_vscode_darwin        || FAILURES=$((FAILURES + 1)); echo ""
    ensure_hyper                || FAILURES=$((FAILURES + 1)); echo ""
    ensure_fonts_darwin         || FAILURES=$((FAILURES + 1)); echo ""
    ensure_tig                  || FAILURES=$((FAILURES + 1)); echo ""
    ensure_vim_plugins          || FAILURES=$((FAILURES + 1)); echo ""
    ensure_plc                  || FAILURES=$((FAILURES + 1)); echo ""
    ensure_fzf_darwin           || FAILURES=$((FAILURES + 1)); echo ""
    ensure_default_shell_darwin || FAILURES=$((FAILURES + 1)); echo ""
    ensure_keyremap_darwin      || FAILURES=$((FAILURES + 1)); echo ""
    ensure_darwin_defaults      || FAILURES=$((FAILURES + 1)); echo ""

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
echo "=========================================="
echo ""

# Run components
install_homebrew
echo ""
install_packages_darwin
echo ""
install_gui_apps_darwin
echo ""
install_ohmyzsh
echo ""
create_directories
echo ""
link_dotfiles
echo ""
link_vscode_darwin
echo ""
link_hyper
echo ""
install_fonts_darwin
echo ""
link_tig
echo ""
install_vim_plugins
echo ""
install_plc
echo ""
install_fzf_darwin
echo ""
set_default_shell_darwin
echo ""
install_keyremap_darwin
echo ""
apply_darwin_defaults
echo ""

echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Open Vim and verify plugins loaded correctly"
echo ""
