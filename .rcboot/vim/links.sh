#!/usr/bin/env bash
# Links: vim — .vimrc, coc settings and the color schemes.

_links_vim() {
    local d="${DOTFILES_DIR:-$HOME/.rc}"
    echo ".vimrc|file|$d/vim/.vimrc|$HOME/.vimrc"

    # coc.nvim only ever reads ~/.vim/coc-settings.json, so that single file is
    # linked rather than the directory around it. The same-inode case — ~/.vim
    # *being* the repo's vim/.vim — is handled by _link_state, which reports it
    # as `ok` instead of trying to back the repo's own file up.
    local coc="$d/vim/.vim/coc-settings.json"
    if [ -f "$coc" ]; then
        echo "coc-settings.json|file|$coc|$HOME/.vim/coc-settings.json"
    fi
}
RC_LINK_SOURCES+=(_links_vim)

ensure_vim_colors() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    local src_dir="$dotfiles_dir/vim/.vim/colors"
    local dst_dir="$HOME/.vim/colors"
    local failed=0 color_file base
    if [ "$(realpath "$src_dir" 2>/dev/null)" != \
        "$(realpath "$dst_dir" 2>/dev/null)" ]; then
        for color_file in "$src_dir"/*.vim; do
            [ -f "$color_file" ] || continue
            base="$(basename "$color_file")"
            _check_link "$base" "$dst_dir/$base" "$color_file" || failed=1
        done
    else
        echo "[OK] Vim colors (source and target are the same directory)"
    fi
    return $failed
}

# Link Vim color schemes (skip if source and target are the same directory).
# A dangling $dst_dir — e.g. ~/.vim/colors is itself a symlink to a repo path
# that moved — used to make realpath fail, every ln fail, and this still print
# [OK] because the exit status went unchecked. Drop a broken link, create the
# directory if absent, and report failures.
link_vim_colors() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    local src_dir="$dotfiles_dir/vim/.vim/colors"
    local dst_dir="$HOME/.vim/colors"
    local color_file
    if [ -L "$dst_dir" ] && [ ! -e "$dst_dir" ]; then
        echo "[FIX] ~/.vim/colors was a dangling symlink; repointing it"
        rm -f "$dst_dir"
    fi
    if [ -L "$dst_dir" ] || [ -d "$dst_dir" ]; then
        if [ "$(realpath "$src_dir")" = "$(realpath "$dst_dir")" ]; then
            echo "[SKIP] Vim colors already in place (source and target are the same)"
            src_dir=""
        fi
    else
        ln -sfn "$src_dir" "$dst_dir"
        echo "[OK] Linked ~/.vim/colors -> $src_dir"
        src_dir=""
    fi
    if [ -n "$src_dir" ]; then
        for color_file in "$src_dir"/*.vim; do
            [ -f "$color_file" ] || continue
            if ln -sf "$color_file" "$dst_dir/$(basename "$color_file")"; then
                echo "[OK] Linked $(basename "$color_file")"
            else
                echo "[FAIL] Could not link $(basename "$color_file") into $dst_dir"
            fi
        done
    fi
}
RC_LINK_HOOKS+=("link_vim_colors|ensure_vim_colors")
