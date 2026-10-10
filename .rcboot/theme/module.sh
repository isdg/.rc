#!/usr/bin/env bash
# Module: theme — no links of its own; checks the generated per-tool files.

# Every per-tool theme file is generated from theme/palette.sh and committed, so
# a stale one means somebody edited the output instead of the palette — and the
# next `theme/generate.sh` will silently revert their change. Cheap to detect
# (it re-renders in memory and compares), so both the installer and the verifier
# check it. Deliberately does not regenerate: writing into the repo during a
# bootstrap run would dirty the tree without being asked.
_check_theme_generated() {
    local gen="${DOTFILES_DIR:-$HOME/.rc}/theme/generate.sh"

    [ -f "$gen" ] || return 0          # older checkout, nothing to check

    if bash "$gen" --check >/dev/null 2>&1; then
        echo "[OK] Theme files match theme/palette.sh"
        return 0
    fi
    echo "[FAIL] Theme files are stale — a generated file was edited by hand:"
    bash "$gen" --check 2>&1 | sed 's/^/       /'
    echo "       Fix: bash $gen   (then commit the result)"
    return 1
}
hook _check_theme_generated _check_theme_generated
