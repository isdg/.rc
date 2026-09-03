#!/usr/bin/env bash
# Component: Link dotfiles (shared)
# Requires: DOTFILES_DIR to be set

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

    _check_link ".zshrc"        "$HOME/.zshrc"        "$dotfiles_dir/zsh/.zshrc"        || failed=1
    _check_link ".zshenv"       "$HOME/.zshenv"       "$dotfiles_dir/zsh/.zshenv"       || failed=1
    _check_link ".vimrc"        "$HOME/.vimrc"        "$dotfiles_dir/vim/.vimrc"         || failed=1
    _check_link ".tmux.conf"    "$HOME/.tmux.conf"    "$dotfiles_dir/tmux/.tmux.conf"    || failed=1
    _check_link ".gitconfig"    "$HOME/.gitconfig"    "$dotfiles_dir/.gitconfig"         || failed=1

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

    # coc.nvim only ever reads ~/.vim/coc-settings.json, so that single file is
    # linked rather than the directory around it. -ef (same inode) covers the
    # case where ~/.vim *is* the repo directory: then there is nothing to link,
    # and a plain _check_link would fail on a regular file.
    local coc_src="$dotfiles_dir/vim/.vim/coc-settings.json"
    local coc_dst="$HOME/.vim/coc-settings.json"
    if [ -f "$coc_src" ]; then
        if [ ! -L "$coc_dst" ] && [ "$coc_dst" -ef "$coc_src" ]; then
            echo "[OK] coc-settings.json (source and target are the same file)"
        else
            _check_link "coc-settings.json" "$coc_dst" "$coc_src" || failed=1
        fi
    fi

    _check_link "nvim config"    "$HOME/.config/nvim"     "$dotfiles_dir/nvim"     || failed=1
    _check_link "ghostty config" "$HOME/.config/ghostty"  "$dotfiles_dir/ghostty"  || failed=1

    if [ -d "$dotfiles_dir/bat" ]; then
        _check_link "bat config"  "$HOME/.config/bat"      "$dotfiles_dir/bat"      || failed=1
    fi

    if [ -d "$dotfiles_dir/hammerspoon" ] && [ "$(uname)" = "Darwin" ]; then
        _check_link "hammerspoon" "$HOME/.hammerspoon"     "$dotfiles_dir/hammerspoon" || failed=1
    fi

    local nom_src="$dotfiles_dir/nom/config.yml"
    if [ -f "$nom_src" ]; then
        local nom_dst
        if [ "$(uname)" = "Darwin" ]; then
            nom_dst="$HOME/Library/Application Support/nom/config.yml"
        else
            nom_dst="${XDG_CONFIG_HOME:-$HOME/.config}/nom/config.yml"
        fi
        _check_link "nom config.yml" "$nom_dst" "$nom_src" || failed=1
    fi

    if [ -f "$dotfiles_dir/claude/settings.json" ]; then
        _check_link "claude/settings.json" "$HOME/.claude/settings.json" \
                    "$dotfiles_dir/claude/settings.json" || failed=1
    fi

    if [ -f "$dotfiles_dir/claude/statusline-command.sh" ]; then
        _check_link "claude/statusline-command.sh" \
                    "$HOME/.claude/statusline-command.sh" \
                    "$dotfiles_dir/claude/statusline-command.sh" || failed=1
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

    # Link Zsh config
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        echo "[BACKUP] Backing up existing .zshrc to .zshrc.backup"
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
    fi
    ln -sf "$dotfiles_dir/zsh/.zshrc" "$HOME/.zshrc"
    echo "[OK] Linked .zshrc"

    # .zshenv, read by non-interactive shells too (tmux popups, nvim's :! …),
    # which is where $FZF_DEFAULT_OPTS_FILE has to come from. Backed up rather
    # than clobbered: a pre-existing one usually carries a toolchain line
    # (cargo, nvm) worth reading before it is discarded.
    if [ -f "$HOME/.zshenv" ] && [ ! -L "$HOME/.zshenv" ]; then
        echo "[BACKUP] Backing up existing .zshenv to .zshenv.backup"
        mv "$HOME/.zshenv" "$HOME/.zshenv.backup"
    fi
    ln -sf "$dotfiles_dir/zsh/.zshenv" "$HOME/.zshenv"
    echo "[OK] Linked .zshenv"

    # The zsh theme needs no link — .zshrc sources it from the repo directly.

    # Link Vim config
    if [ -f "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
        echo "[BACKUP] Backing up existing .vimrc to .vimrc.backup"
        mv "$HOME/.vimrc" "$HOME/.vimrc.backup"
    fi
    ln -sf "$dotfiles_dir/vim/.vimrc" "$HOME/.vimrc"
    echo "[OK] Linked .vimrc"

    # Link Tmux config
    if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
        echo "[BACKUP] Backing up existing .tmux.conf to .tmux.conf.backup"
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup"
    fi
    ln -sf "$dotfiles_dir/tmux/.tmux.conf" "$HOME/.tmux.conf"
    echo "[OK] Linked .tmux.conf"

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

    # Link Git config
    if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
        echo "[BACKUP] Backing up existing .gitconfig to .gitconfig.backup"
        mv "$HOME/.gitconfig" "$HOME/.gitconfig.backup"
    fi
    ln -sf "$dotfiles_dir/.gitconfig" "$HOME/.gitconfig"
    echo "[OK] Linked .gitconfig"

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

    # Link coc.nvim settings (see the matching note in ensure_dotfiles)
    local coc_src="$dotfiles_dir/vim/.vim/coc-settings.json"
    local coc_dst="$HOME/.vim/coc-settings.json"
    if [ -f "$coc_src" ]; then
        if [ ! -L "$coc_dst" ] && [ "$coc_dst" -ef "$coc_src" ]; then
            echo "[SKIP] coc-settings.json already in place (source and target are the same file)"
        else
            mkdir -p "$HOME/.vim"
            if [ -f "$coc_dst" ] && [ ! -L "$coc_dst" ]; then
                echo "[BACKUP] Backing up existing coc-settings.json to coc-settings.json.backup"
                mv "$coc_dst" "$coc_dst.backup"
            fi
            ln -sf "$coc_src" "$coc_dst"
            echo "[OK] Linked coc-settings.json"
        fi
    fi

    # Link Neovim config (skip if already pointing to the right place)
    local nvim_src="$dotfiles_dir/nvim"
    local nvim_dst="$HOME/.config/nvim"
    if [ "$(realpath "$nvim_src" 2>/dev/null)" != "$(realpath "$nvim_dst" 2>/dev/null)" ]; then
        if [ -d "$nvim_dst" ] && [ ! -L "$nvim_dst" ]; then
            echo "[BACKUP] Backing up existing nvim config to nvim.backup"
            mv "$nvim_dst" "$HOME/.config/nvim.backup"
        fi
        ln -sf "$nvim_src" "$nvim_dst"
        echo "[OK] Linked nvim config"
    else
        echo "[SKIP] Neovim config already in place (source and target are the same)"
    fi

    # Link Ghostty config (skip if already pointing to the right place)
    local ghostty_src="$dotfiles_dir/ghostty"
    local ghostty_dst="$HOME/.config/ghostty"
    if [ "$(realpath "$ghostty_src" 2>/dev/null)" != "$(realpath "$ghostty_dst" 2>/dev/null)" ]; then
        if [ -d "$ghostty_dst" ] && [ ! -L "$ghostty_dst" ]; then
            echo "[BACKUP] Backing up existing ghostty config to ghostty.backup"
            mv "$ghostty_dst" "$HOME/.config/ghostty.backup"
        fi
        ln -sf "$ghostty_src" "$ghostty_dst"
        echo "[OK] Linked ghostty config"
    else
        echo "[SKIP] Ghostty config already in place (source and target are the same)"
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

    # Link k9s skins + seed the active-skin symlink (default: current mode).
    # k9s never writes into skins/, so symlinking just that subdir keeps its
    # runtime state (logs, clusters/) out of the repo. toggle_theme.sh flips
    # skin-active.yaml afterwards; config.yaml points ui.skin at it.
    if [ -d "$dotfiles_dir/k9s/skins" ]; then
        local k9s_dst
        if [ "$(uname)" = "Darwin" ]; then
            k9s_dst="$HOME/Library/Application Support/k9s"
        else
            k9s_dst="${XDG_CONFIG_HOME:-$HOME/.config}/k9s"
        fi
        mkdir -p "$k9s_dst"
        ln -sf "vs_$(cat "$theme_file").yaml" "$dotfiles_dir/k9s/skins/skin-active.yaml"
        if [ -e "$k9s_dst/skins" ] && [ ! -L "$k9s_dst/skins" ]; then
            mv "$k9s_dst/skins" "$k9s_dst/skins.backup"
        fi
        ln -sfn "$dotfiles_dir/k9s/skins" "$k9s_dst/skins"
        echo "[OK] Linked k9s skins (set ui.skin: skin-active in $k9s_dst/config.yaml)"

        # Log-helper plugins (snapshot→nvim, stream→tmux). Single file, k9s
        # only reads it, so a per-file symlink is safe.
        if [ -f "$dotfiles_dir/k9s/plugins.yaml" ]; then
            if [ -e "$k9s_dst/plugins.yaml" ] && [ ! -L "$k9s_dst/plugins.yaml" ]; then
                mv "$k9s_dst/plugins.yaml" "$k9s_dst/plugins.yaml.backup"
            fi
            ln -sf "$dotfiles_dir/k9s/plugins.yaml" "$k9s_dst/plugins.yaml"
            echo "[OK] Linked k9s plugins.yaml"
        fi
    fi

    # Link bat config dir (carries custom vs_dark/vs_light preview themes).
    # Rebuild bat's theme cache so BAT_THEME=vs_dark/vs_light resolves.
    local bat_src="$dotfiles_dir/bat"
    local bat_dst="$HOME/.config/bat"
    if [ -d "$bat_src" ] && [ "$(realpath "$bat_src" 2>/dev/null)" != "$(realpath "$bat_dst" 2>/dev/null)" ]; then
        if [ -d "$bat_dst" ] && [ ! -L "$bat_dst" ]; then
            echo "[BACKUP] Backing up existing bat config to bat.backup"
            mv "$bat_dst" "$HOME/.config/bat.backup"
        fi
        ln -sf "$bat_src" "$bat_dst"
        echo "[OK] Linked bat config"
        if command -v bat >/dev/null 2>&1; then
            bat cache --build >/dev/null 2>&1 && echo "[OK] Rebuilt bat theme cache"
        fi
    fi

    # Link Hammerspoon config (macOS only; carries the translation popup).
    local hs_src="$dotfiles_dir/hammerspoon"
    local hs_dst="$HOME/.hammerspoon"
    if [ -d "$hs_src" ] && [ "$(uname)" = "Darwin" ] \
       && [ "$(realpath "$hs_src" 2>/dev/null)" != "$(realpath "$hs_dst" 2>/dev/null)" ]; then
        if [ -d "$hs_dst" ] && [ ! -L "$hs_dst" ]; then
            echo "[BACKUP] Backing up existing .hammerspoon to .hammerspoon.backup"
            mv "$hs_dst" "$HOME/.hammerspoon.backup"
        fi
        ln -sf "$hs_src" "$hs_dst"
        echo "[OK] Linked Hammerspoon config"
    fi

    # Link nom config (RSS reader). macOS uses Library/Application Support,
    # Linux uses XDG ~/.config.
    local nom_src="$dotfiles_dir/nom/config.yml"
    if [ -f "$nom_src" ]; then
        local nom_dst
        if [ "$(uname)" = "Darwin" ]; then
            nom_dst="$HOME/Library/Application Support/nom/config.yml"
        else
            nom_dst="${XDG_CONFIG_HOME:-$HOME/.config}/nom/config.yml"
        fi
        mkdir -p "$(dirname "$nom_dst")"
        if [ -f "$nom_dst" ] && [ ! -L "$nom_dst" ]; then
            echo "[BACKUP] Backing up existing nom config.yml to config.yml.backup"
            mv "$nom_dst" "$nom_dst.backup"
        fi
        ln -sf "$nom_src" "$nom_dst"
        echo "[OK] Linked nom config.yml"
    fi

    # Link Claude Code settings (settings.json.local stays untouched — it's
    # the per-machine override that shouldn't live in the repo)
    if [ -f "$dotfiles_dir/claude/settings.json" ]; then
        mkdir -p "$HOME/.claude"
        if [ -f "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
            echo "[BACKUP] Backing up existing claude settings.json to settings.json.backup"
            mv "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup"
        fi
        ln -sf "$dotfiles_dir/claude/settings.json" "$HOME/.claude/settings.json"
        echo "[OK] Linked claude/settings.json"
    fi

    # The statusLine command settings.json points at. Linked separately because
    # settings.json names it by path, so a machine with the settings but not the
    # script gets a prompt that silently renders nothing.
    if [ -f "$dotfiles_dir/claude/statusline-command.sh" ]; then
        mkdir -p "$HOME/.claude"
        if [ -f "$HOME/.claude/statusline-command.sh" ] && [ ! -L "$HOME/.claude/statusline-command.sh" ]; then
            echo "[BACKUP] Backing up existing claude statusline-command.sh to statusline-command.sh.backup"
            mv "$HOME/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh.backup"
        fi
        ln -sf "$dotfiles_dir/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
        echo "[OK] Linked claude/statusline-command.sh"
    fi
}
