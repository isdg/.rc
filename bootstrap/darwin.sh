#!/usr/bin/env bash
#
# Bootstrap script for Darwin (macOS) systems
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

# Load components
source "$SCRIPT_DIR/components/helpers.sh"
source "$SCRIPT_DIR/components/homebrew.sh"
source "$SCRIPT_DIR/components/packages_darwin.sh"
source "$SCRIPT_DIR/components/gui_apps_darwin.sh"
source "$SCRIPT_DIR/components/directories.sh"
source "$SCRIPT_DIR/components/dotfiles.sh"
source "$SCRIPT_DIR/components/vscode.sh"
source "$SCRIPT_DIR/components/fonts.sh"
source "$SCRIPT_DIR/components/tig.sh"
source "$SCRIPT_DIR/components/vim.sh"
source "$SCRIPT_DIR/components/plc.sh"
source "$SCRIPT_DIR/components/tmux_plugins.sh"
source "$SCRIPT_DIR/components/hr.sh"
source "$SCRIPT_DIR/components/fzf.sh"
source "$SCRIPT_DIR/components/shell.sh"
source "$SCRIPT_DIR/components/keyremap.sh"
source "$SCRIPT_DIR/components/darwin_defaults.sh"

# ── Component registry ─────────────────────────────────────────────────────────
# One "install_func|ensure_func" per component, in run order. Add a line to ship
# another component; both modes pick it up.
#
# CORE  — the terminal experience: brew, the package set for the active profile,
#         shell, dotfile symlinks, fonts, vim/tmux/fzf/tig wiring. Always runs.
#         The keyboard remap lives here rather than with the other macOS tweaks:
#         it changes what every keystroke does, so a --minimal box without it is
#         not usable in the way the rest of this config assumes.
# EXTRA — GUI apps, VS Code, the Rust-built side tools (plc, hr, omni, orchbus)
#         and macOS system defaults. Skipped by --minimal.
BOOTSTRAP_CORE_FUNCS=(
    "install_homebrew|ensure_homebrew"
    "install_packages_darwin|ensure_packages_darwin"
    "create_directories|ensure_directories"
    "link_dotfiles|ensure_dotfiles"
    "install_fonts_darwin|ensure_fonts_darwin"
    "link_tig|ensure_tig"
    "install_vim_plugins|ensure_vim_plugins"
    "install_fzf_darwin|ensure_fzf_darwin"
    "set_default_shell_darwin|ensure_default_shell_darwin"
    "install_keyremap_darwin|ensure_keyremap_darwin"
)
BOOTSTRAP_EXTRA_FUNCS=(
    "install_gui_apps_darwin|ensure_gui_apps_darwin"
    "link_vscode_darwin|ensure_vscode_darwin"
    "install_plc|ensure_plc"
    "install_tmux_plugins|ensure_tmux_plugins"
    "install_hr|ensure_hr"
    "apply_darwin_defaults|ensure_darwin_defaults"
)

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

# Components for the selected profile, as "install|ensure" pairs on stdout.
_profile_components() {
    printf '%s\n' "${BOOTSTRAP_CORE_FUNCS[@]}"
    if [ "$BOOTSTRAP_MINIMAL" != "1" ]; then
        printf '%s\n' "${BOOTSTRAP_EXTRA_FUNCS[@]}"
    fi
}

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

    FAILURES=0
    set +e  # collect all failures instead of stopping at first

    while IFS='|' read -r _install _ensure; do
        [ -z "$_ensure" ] && continue
        "$_ensure" || FAILURES=$((FAILURES + 1))
        echo ""
    done < <(_profile_components)

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

while IFS='|' read -r _install _ensure; do
    [ -z "$_install" ] && continue
    "$_install"
    echo ""
done < <(_profile_components)

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
    echo "Run ./bootstrap/darwin.sh for the full set."
fi
echo ""
