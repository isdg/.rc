#!/usr/bin/env bash
# Component: Link dotfiles (shared)
# Requires: DOTFILES_DIR to be set

# Every plain "link this path to that path" dotfile, one `label|kind|src|dst`
# line each. A function rather than an array because the entries need runtime
# resolution: $HOME, the Darwin-vs-XDG split for nom, and the guards that drop
# an entry whose source this checkout does not carry.
#
# link_dotfiles, ensure_dotfiles and the bootstrap journal all read this one
# list, so they cannot drift apart — which they had: ensure_dotfiles used to
# verify a strict subset of what link_dotfiles wrote.
#
# Deliberately not here, because they are not a straight a->b link: the vim
# colors directory with its per-file fallback, the theme mode file, and the
# generated *-active files inside the repo. Those stay hand-written below.
_dotfile_links() {
    local d="${DOTFILES_DIR:-$HOME/.rc}"

    echo ".zshrc|file|$d/zsh/.zshrc|$HOME/.zshrc"
    echo ".zshenv|file|$d/zsh/.zshenv|$HOME/.zshenv"
    echo ".vimrc|file|$d/vim/.vimrc|$HOME/.vimrc"
    echo ".tmux.conf|file|$d/tmux/.tmux.conf|$HOME/.tmux.conf"
    echo ".gitconfig|file|$d/.gitconfig|$HOME/.gitconfig"
    echo "nvim config|dir|$d/nvim|$HOME/.config/nvim"
    echo "ghostty config|dir|$d/ghostty|$HOME/.config/ghostty"

    # coc.nvim only ever reads ~/.vim/coc-settings.json, so that single file is
    # linked rather than the directory around it. The same-inode case — ~/.vim
    # *being* the repo's vim/.vim — is handled by _link_state, which reports it
    # as `ok` instead of trying to back the repo's own file up.
    if [ -f "$d/vim/.vim/coc-settings.json" ]; then
        echo "coc-settings.json|file|$d/vim/.vim/coc-settings.json|$HOME/.vim/coc-settings.json"
    fi

    # Carries the custom vs_dark/vs_light preview themes.
    if [ -d "$d/bat" ]; then
        echo "bat config|dir|$d/bat|$HOME/.config/bat"
    fi

    # macOS only; carries the translation popup.
    if [ -d "$d/hammerspoon" ] && [ "$(uname)" = "Darwin" ]; then
        echo "hammerspoon|dir|$d/hammerspoon|$HOME/.hammerspoon"
    fi

    # k9s never writes into skins/, so symlinking just that subdir keeps its
    # runtime state (logs, clusters/) out of the repo. plugins.yaml is the
    # log-helper pair (snapshot→nvim, stream→tmux); k9s only reads it, so a
    # per-file symlink is safe. Both used to clobber without even a [BACKUP]
    # line; going through _relink is what fixed that.
    if [ -d "$d/k9s/skins" ]; then
        local k9s
        if [ "$(uname)" = "Darwin" ]; then
            k9s="$HOME/Library/Application Support/k9s"
        else
            k9s="${XDG_CONFIG_HOME:-$HOME/.config}/k9s"
        fi
        echo "k9s skins|dir|$d/k9s/skins|$k9s/skins"
        if [ -f "$d/k9s/plugins.yaml" ]; then
            echo "k9s plugins.yaml|file|$d/k9s/plugins.yaml|$k9s/plugins.yaml"
        fi
    fi

    # nom (RSS reader): macOS uses Library/Application Support, Linux XDG.
    if [ -f "$d/nom/config.yml" ]; then
        if [ "$(uname)" = "Darwin" ]; then
            echo "nom config.yml|file|$d/nom/config.yml|$HOME/Library/Application Support/nom/config.yml"
        else
            echo "nom config.yml|file|$d/nom/config.yml|${XDG_CONFIG_HOME:-$HOME/.config}/nom/config.yml"
        fi
    fi

    # settings.json.local stays untouched — it is the per-machine override that
    # shouldn't live in the repo.
    if [ -f "$d/claude/settings.json" ]; then
        echo "claude/settings.json|file|$d/claude/settings.json|$HOME/.claude/settings.json"
    fi

    # The statusLine command settings.json points at, linked separately because
    # settings.json names it by path: a machine with the settings but not the
    # script gets a prompt that silently renders nothing.
    if [ -f "$d/claude/statusline-command.sh" ]; then
        echo "claude/statusline-command.sh|file|$d/claude/statusline-command.sh|$HOME/.claude/statusline-command.sh"
    fi

    return 0
}

# Every per-tool theme file is generated from theme/palette.sh and committed, so
# a stale one means somebody edited the output instead of the palette — and the
# next `theme/generate.sh` will silently revert their change. Cheap to detect
# (it re-renders in memory and compares), so both the installer and the verifier
# check it. Deliberately does not regenerate: writing into the repo during a
# bootstrap run would dirty the tree without being asked.
_check_theme_generated() {
    local dotfiles_dir="$1"
    local gen="$dotfiles_dir/theme/generate.sh"

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

ensure_dotfiles() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    echo "[STEP] Verifying dotfiles..."
    local failed=0

    # Process substitution, not a pipe, so $failed survives the loop.
    while IFS='|' read -r label _kind src dst; do
        _check_link "$label" "$dst" "$src" || failed=1
    done < <(_dotfile_links)

    _check_theme_generated "$dotfiles_dir" || failed=1

    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "[OK] TPM installed"
    else
        echo "[FAIL] TPM not installed (~/.tmux/plugins/tpm missing)"
        failed=1
    fi

    # Vim color schemes
    local src_dir="$dotfiles_dir/vim/.vim/colors"
    local dst_dir="$HOME/.vim/colors"
    if [ "$(realpath "$src_dir" 2>/dev/null)" != "$(realpath "$dst_dir" 2>/dev/null)" ]; then
        for color_file in "$src_dir"/*.vim; do
            [ -f "$color_file" ] || continue
            local base
            base="$(basename "$color_file")"
            _check_link "$base" "$dst_dir/$base" "$color_file" || failed=1
        done
    else
        echo "[OK] Vim colors (source and target are the same directory)"
    fi

    return $failed
}

link_dotfiles() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    echo "[STEP] Linking dotfiles..."

    # Checked before anything is linked: these files are about to be symlinked
    # into ~/, and a stale one is far more confusing once it is live. Reported,
    # not fatal — a stale theme file should not stop the rest of a bootstrap.
    _check_theme_generated "$dotfiles_dir" || true

    # Every plain a->b link, from the one table in _dotfile_links. .zshenv is in
    # there too: read by non-interactive shells (tmux popups, nvim's :! …),
    # which is where $FZF_DEFAULT_OPTS_FILE has to come from, and backed up
    # rather than clobbered because a pre-existing one usually carries a
    # toolchain line (cargo, nvm) worth reading before it is discarded.
    #
    # The zsh theme needs no link — .zshrc sources it from the repo directly.
    #
    # A [FAIL] from one entry does not stop the others: same policy as the vim
    # colors loop below, and --ensure is the net that catches it afterwards.
    # Process substitution, not a pipe, so $bat_state survives the loop.
    local bat_state=""
    while IFS='|' read -r label kind src dst; do
        if [ "$label" = "bat config" ]; then
            bat_state="$(_link_state "$src" "$dst")"
        fi
        _relink "$label" "$kind" "$src" "$dst" || true
    done < <(_dotfile_links)

    # Apply to any already-running tmux server. Unlike ghostty/k9s, tmux's
    # config reads the theme mode file directly at parse time (see the
    # run-shell block in tmux/.tmux.conf), so there's no "active" symlink to
    # seed here — just re-source so an existing session reflects it now
    # instead of only on the next `tmux new`.
    if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
        tmux source-file "$HOME/.tmux.conf" && echo "[OK] Reloaded tmux config for running server"
    fi

    # Install TPM (Tmux Plugin Manager)
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "[STEP] Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        echo "[OK] TPM installed. In tmux, press prefix + I to install plugins."
    else
        echo "[SKIP] TPM already installed"
    fi

    # Link Vim color schemes (skip if source and target are the same directory).
    # A dangling $dst_dir — e.g. ~/.vim/colors is itself a symlink to a repo path
    # that moved — used to make realpath fail, every ln fail, and this still print
    # [OK] because the exit status went unchecked. Drop a broken link, create the
    # directory if absent, and report failures.
    local src_dir="$dotfiles_dir/vim/.vim/colors"
    local dst_dir="$HOME/.vim/colors"
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

    # Theme source of truth + ghostty active-theme include (default: light).
    # toggle_theme.sh maintains both afterwards.
    local theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/isg/theme"
    if [ ! -f "$theme_file" ]; then
        mkdir -p "$(dirname "$theme_file")"
        echo light > "$theme_file"
        echo "[OK] Seeded theme mode file ($theme_file = light)"
    fi
    local active="$dotfiles_dir/ghostty/theme-active.conf"
    if [ ! -e "$active" ]; then
        ln -sf "theme-$(cat "$theme_file").conf" "$active"
        echo "[OK] Seeded ghostty/theme-active.conf -> theme-$(cat "$theme_file").conf"
    fi

    # Ghostty width include. Seeded because a missing include is not ignored:
    # ghostty reports "error opening config-file ... FileNotFound" and drops
    # window-padding-x entirely, so the window opens with no padding at all.
    # width.sh (alias `ww`) rewrites this file afterwards.
    local width_active="$dotfiles_dir/ghostty/width-active.conf"
    if [ ! -f "$width_active" ]; then
        printf '# GENERATED by width.sh (alias `ww`) — edits here are overwritten.\n# Included by ghostty/config; gitignored so width changes never dirty the repo.\nwindow-padding-x = 400\n' > "$width_active"
        echo "[OK] Seeded ghostty/width-active.conf (window-padding-x = 400)"
    fi

    # fzf options file, same idiom. Seeded unconditionally (-e is false for a
    # dangling link, and a dangling $FZF_DEFAULT_OPTS_FILE is worse than none:
    # fzf exits 2 on a missing file instead of falling back to its defaults).
    if [ -d "$dotfiles_dir/fzf" ]; then
        ln -sf "opts-$(cat "$theme_file").conf" "$dotfiles_dir/fzf/opts-active.conf"
        echo "[OK] Seeded fzf/opts-active.conf -> opts-$(cat "$theme_file").conf"
    fi

    # The k9s skins/ and plugins.yaml links themselves come from the table; what
    # is left here is the active-skin symlink *inside* the repo, which the table
    # cannot express. toggle_theme.sh flips it afterwards; config.yaml points
    # ui.skin at it, which is the one bit of manual setup k9s needs.
    if [ -d "$dotfiles_dir/k9s/skins" ]; then
        ln -sf "vs_$(cat "$theme_file").yaml" "$dotfiles_dir/k9s/skins/skin-active.yaml"
        echo "[INFO] k9s: set ui.skin: skin-active in its config.yaml"
    fi

    # bat reads its themes out of ~/.config/bat (linked from the table above),
    # but only after its cache is rebuilt — without this BAT_THEME=vs_dark /
    # vs_light does not resolve. Only when the link actually changed: a rebuild
    # costs a second, and on a settled machine there is nothing new to compile.
    if [ -n "$bat_state" ] && [ "$bat_state" != ok ] && command -v bat >/dev/null 2>&1; then
        bat cache --build >/dev/null 2>&1 && echo "[OK] Rebuilt bat theme cache"
    fi

}
