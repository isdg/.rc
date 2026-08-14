#!/usr/bin/env bash
# Component: VSCode settings, keybindings and snippets
# Requires: DOTFILES_DIR to be set

# Snippet files are discovered, not listed. A hardcoded list silently skips any
# file it does not name — which is how cpp-author and palace went unlinked while
# an entry for an author.code-snippets that no longer exists sat here looking
# fine. The [ -f ] guard also makes an empty glob a no-op.
_vscode_snippets() {
    local dotfiles_dir="$1" f
    for f in "$dotfiles_dir"/vscode/*.code-snippets; do
        [ -f "$f" ] && printf '%s\n' "$f"
    done
}

# Both verifiers differ only in where VSCode keeps its user directory, so the
# darwin/linux entry points below just pass that path in.
_ensure_vscode() {
    local dotfiles_dir="$1" vscode_dir="$2"
    echo "[STEP] Verifying VSCode..."
    local failed=0 f base

    for f in settings.json keybindings.json; do
        [ -f "$dotfiles_dir/vscode/$f" ] || continue
        _check_link "VSCode $f" "$vscode_dir/$f" "$dotfiles_dir/vscode/$f" || failed=1
    done

    # Process substitution, not a pipe: the loop has to run in this shell for
    # $failed to survive it.
    while read -r f; do
        base="$(basename "$f")"
        _check_link "VSCode $base" "$vscode_dir/snippets/$base" "$f" || failed=1
    done < <(_vscode_snippets "$dotfiles_dir")

    return $failed
}

_link_vscode() {
    local dotfiles_dir="$1" vscode_dir="$2"
    echo "[STEP] Setting up VSCode..."

    mkdir -p "$vscode_dir/snippets"

    local f
    for f in settings.json keybindings.json; do
        [ -f "$dotfiles_dir/vscode/$f" ] || continue
        ln -sf "$dotfiles_dir/vscode/$f" "$vscode_dir/$f"
        echo "[OK] Linked VSCode $f"
    done

    while read -r f; do
        ln -sf "$f" "$vscode_dir/snippets/$(basename "$f")"
        echo "[OK] Linked $(basename "$f")"
    done < <(_vscode_snippets "$dotfiles_dir")
}

_vscode_user_dir_darwin() { echo "$HOME/Library/Application Support/Code/User"; }
_vscode_user_dir_linux()  { echo "$HOME/.config/Code/User"; }

ensure_vscode_darwin() { _ensure_vscode "${DOTFILES_DIR:-$HOME/.rc}" "$(_vscode_user_dir_darwin)"; }
ensure_vscode_linux()  { _ensure_vscode "${DOTFILES_DIR:-$HOME/.rc}" "$(_vscode_user_dir_linux)"; }
link_vscode_darwin()   { _link_vscode   "${DOTFILES_DIR:-$HOME/.rc}" "$(_vscode_user_dir_darwin)"; }
link_vscode_linux()    { _link_vscode   "${DOTFILES_DIR:-$HOME/.rc}" "$(_vscode_user_dir_linux)"; }
