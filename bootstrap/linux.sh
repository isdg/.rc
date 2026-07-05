#!/usr/bin/env bash
#
# Bootstrap script for Linux systems
# Assembles modular components for dotfiles setup
#
# Usage:
#   ./linux.sh           — install / configure everything
#   ./linux.sh --ensure  — verify everything is in place (no changes made)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
export DOTFILES_DIR

# Load components
source "$SCRIPT_DIR/components/helpers.sh"
source "$SCRIPT_DIR/components/packages_linux.sh"
source "$SCRIPT_DIR/components/ohmyzsh.sh"
source "$SCRIPT_DIR/components/zsh_syntax_linux.sh"
source "$SCRIPT_DIR/components/directories.sh"
source "$SCRIPT_DIR/components/dotfiles.sh"
source "$SCRIPT_DIR/components/vscode.sh"
source "$SCRIPT_DIR/components/hyper.sh"
source "$SCRIPT_DIR/components/fonts.sh"
source "$SCRIPT_DIR/components/tig.sh"
source "$SCRIPT_DIR/components/vim.sh"
source "$SCRIPT_DIR/components/plc.sh"
source "$SCRIPT_DIR/components/hr.sh"
source "$SCRIPT_DIR/components/fzf.sh"
source "$SCRIPT_DIR/components/shell.sh"

# ── Ensure mode ────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--ensure" ]]; then
    echo "=========================================="
    echo "  Dotfiles Verify for Linux"
    echo "=========================================="
    echo ""

    FAILURES=0
    set +e  # collect all failures instead of stopping at first

    ensure_packages_linux      || FAILURES=$((FAILURES + 1)); echo ""
    ensure_ohmyzsh             || FAILURES=$((FAILURES + 1)); echo ""
    ensure_zsh_syntax_linux    || FAILURES=$((FAILURES + 1)); echo ""
    ensure_directories         || FAILURES=$((FAILURES + 1)); echo ""
    ensure_dotfiles            || FAILURES=$((FAILURES + 1)); echo ""
    ensure_vscode_linux        || FAILURES=$((FAILURES + 1)); echo ""
    ensure_hyper               || FAILURES=$((FAILURES + 1)); echo ""
    ensure_fonts_linux         || FAILURES=$((FAILURES + 1)); echo ""
    ensure_tig                 || FAILURES=$((FAILURES + 1)); echo ""
    ensure_vim_plugins         || FAILURES=$((FAILURES + 1)); echo ""
    ensure_plc                 || FAILURES=$((FAILURES + 1)); echo ""
    ensure_hr                  || FAILURES=$((FAILURES + 1)); echo ""
    ensure_fzf_linux           || FAILURES=$((FAILURES + 1)); echo ""
    ensure_default_shell_linux || FAILURES=$((FAILURES + 1)); echo ""

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
echo "=========================================="
echo ""

# Run components
install_packages_linux
echo ""
install_ohmyzsh
echo ""
install_zsh_syntax_linux
echo ""
create_directories
echo ""
link_dotfiles
echo ""
link_vscode_linux
echo ""
link_hyper
echo ""
install_fonts_linux
echo ""
link_tig
echo ""
install_vim_plugins
echo ""
install_plc
echo ""
install_hr
echo ""
install_fzf_linux
echo ""
set_default_shell_linux
echo ""

echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Open Vim and verify plugins loaded correctly"
echo ""
