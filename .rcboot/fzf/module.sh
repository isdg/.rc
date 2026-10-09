#!/usr/bin/env bash
# Module: fzf — its active options file, inside the repo, and the shell
# integration.

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
hook seed_fzf_opts

fragment zsh/rc.d/09-fzf-init.zsh
fragment zsh/rc.d/16-fzf.zsh
fragment tmux/rc.d/06-fzf-env.conf

source "$RC_BOOT/fzf/fzf.sh"
step "install_fzf_$RC_OS" "ensure_fzf_$RC_OS"
