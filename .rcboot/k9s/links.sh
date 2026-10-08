#!/usr/bin/env bash
# Links: k9s — skins/ and plugins.yaml, the active skin, and ui.skin.

# k9s keeps its config under Application Support on macOS and XDG elsewhere.
_k9s_dir() {
    if [ "$(uname)" = "Darwin" ]; then
        echo "$HOME/Library/Application Support/k9s"
    else
        echo "${XDG_CONFIG_HOME:-$HOME/.config}/k9s"
    fi
}

# k9s never writes into skins/, so symlinking just that subdir keeps its
# runtime state (logs, clusters/) out of the repo. plugins.yaml is the
# log-helper pair (snapshot→nvim, stream→tmux); k9s only reads it.
_links_k9s() {
    local d="${DOTFILES_DIR:-$HOME/.rc}" k9s
    [ -d "$d/k9s/skins" ] || return 0
    k9s="$(_k9s_dir)"
    echo "k9s skins|dir|$d/k9s/skins|$k9s/skins"
    if [ -f "$d/k9s/plugins.yaml" ]; then
        echo "k9s plugins.yaml|file|$d/k9s/plugins.yaml|$k9s/plugins.yaml"
    fi
}
RC_LINK_SOURCES+=(_links_k9s)

# The skin only loads if config.yaml names it, and k9s regenerates that file
# from its defaults whenever it cannot parse one — dropping ui.skin with it.
# So: copy the seed when there is no config at all, otherwise re-add the key.
_ensure_k9s_skin() {
    local dotfiles_dir="$1"
    local seed="$dotfiles_dir/k9s/config.yaml"
    local k9s_dir live tmp
    k9s_dir="$(_k9s_dir)"
    live="$k9s_dir/config.yaml"

    [ -f "$seed" ] || return 0          # older checkout, nothing to seed

    if [ ! -f "$live" ]; then
        mkdir -p "$k9s_dir" && cp "$seed" "$live" || {
            echo "[FAIL] Could not seed $live"
            return 1
        }
        echo "[OK] Seeded k9s config.yaml (ui.skin: skin-active)"
        return 0
    fi

    if grep -qE '^[[:space:]]*skin:' "$live"; then
        echo "[SKIP] k9s config.yaml already sets ui.skin"
        return 0
    fi

    # Indent is taken from the ui: line rather than hardcoded, so this still
    # lands correctly if k9s ever restyles the file it writes.
    tmp="$(mktemp)" || return 1
    if awk '
        /^[[:space:]]*ui:[[:space:]]*$/ && !seen {
            print
            indent = $0; sub(/ui:.*/, "", indent)
            print indent "  skin: skin-active"
            seen = 1
            next
        }
        { print }
        END { exit !seen }
    ' "$live" > "$tmp"; then
        # cat, not mv: keeps the live file's inode and its 0600 mode.
        cat "$tmp" > "$live"
        rm -f "$tmp"
        echo "[OK] Restored ui.skin: skin-active in k9s config.yaml"
    else
        rm -f "$tmp"
        echo "[FAIL] k9s config.yaml has no ui: block; add 'skin: skin-active' under one"
        return 1
    fi
}

# Verify only — _ensure_k9s_skin is what repairs it.
_check_k9s_skin() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    local live
    live="$(_k9s_dir)/config.yaml"

    [ -f "$dotfiles_dir/k9s/config.yaml" ] || return 0

    if [ ! -f "$live" ]; then
        echo "[FAIL] k9s config.yaml missing — the skin will not load"
        return 1
    fi
    if grep -qE '^[[:space:]]*skin:' "$live"; then
        echo "[OK] k9s config.yaml sets ui.skin"
        return 0
    fi
    echo "[FAIL] k9s config.yaml has no ui.skin — the skin will not load"
    return 1
}

# The skin-active symlink lives *inside* the repo, which a row cannot express;
# toggle_theme.sh flips it afterwards. Pointing ui.skin at it used to be
# manual, and k9s silently dropped the key when it rewrote its config.
seed_k9s_skin() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}" mode
    if [ -d "$dotfiles_dir/k9s/skins" ]; then
        mode="$(_theme_mode)"
        ln -sf "vs_$mode.yaml" "$dotfiles_dir/k9s/skins/skin-active.yaml"
        echo "[OK] Seeded k9s/skin-active.yaml -> vs_$mode.yaml"
    fi
    _ensure_k9s_skin "$dotfiles_dir"
}
RC_LINK_HOOKS+=("seed_k9s_skin|_check_k9s_skin")
