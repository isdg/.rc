#!/usr/bin/env bash
# Links: fzf's active options file, inside the repo.

# Seeded unconditionally (-e is false for a dangling link, and a dangling
# $FZF_DEFAULT_OPTS_FILE is worse than none: fzf exits 2 on a missing file
# instead of falling back to its defaults).
seed_fzf_opts() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}" mode
    [ -d "$dotfiles_dir/fzf" ] || return 0
    mode="$(_theme_mode)"
    ln -sf "opts-$mode.conf" "$dotfiles_dir/fzf/opts-active.conf"
    echo "[OK] Seeded fzf/opts-active.conf -> opts-$mode.conf"
}
RC_LINK_HOOKS+=("seed_fzf_opts|")
