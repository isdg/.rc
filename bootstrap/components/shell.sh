#!/usr/bin/env bash
# Component: Set default shell (shared)

ensure_default_shell_darwin() {
    echo "[STEP] Verifying default shell..."
    local brew_zsh
    brew_zsh="$(brew --prefix 2>/dev/null)/bin/zsh"
    if [ "$SHELL" = "$brew_zsh" ]; then
        echo "[OK] Default shell is Homebrew zsh ($brew_zsh)"
    else
        echo "[FAIL] Default shell is $SHELL (expected $brew_zsh)"
        return 1
    fi
}

# The login shell recorded in /etc/passwd. $SHELL is inherited from whatever
# started the script and stays stale until the next login, so it cannot answer
# "did chsh work?" — this can.
_login_shell_linux() {
    getent passwd "$USER" 2>/dev/null | cut -d: -f7
}

ensure_default_shell_linux() {
    echo "[STEP] Verifying default shell..."
    local zsh_path login_shell
    zsh_path="$(which zsh 2>/dev/null)"
    login_shell="$(_login_shell_linux)"
    if [ -n "$zsh_path" ] && [ "$login_shell" = "$zsh_path" ]; then
        echo "[OK] Default shell is zsh ($zsh_path)"
    else
        echo "[FAIL] Login shell is ${login_shell:-unknown} (expected zsh at ${zsh_path:-<not installed>})"
        return 1
    fi
}

set_default_shell_darwin() {
    echo "[STEP] Setting Zsh as default shell..."

    local brew_zsh
    brew_zsh="$(brew --prefix)/bin/zsh"

    if [ "$SHELL" != "$brew_zsh" ]; then
        echo "[INFO] Current shell: $SHELL"

        # Add Homebrew zsh to /etc/shells if not present
        if ! grep -q "$brew_zsh" /etc/shells 2>/dev/null; then
            echo "[SUDO] Adding Homebrew zsh to /etc/shells..."
            if echo "$brew_zsh" | sudo tee -a /etc/shells > /dev/null 2>&1; then
                echo "[OK] Added Homebrew zsh to /etc/shells"
            else
                echo "[WARN] Could not add to /etc/shells (requires sudo)"
            fi
        fi

        # Try to change shell
        if chsh -s "$brew_zsh" 2>/dev/null; then
            echo "[OK] Default shell changed to Homebrew zsh"
        else
            echo "[WARN] Could not change default shell automatically"
            echo "[INFO] You can change it manually with:"
            echo "    sudo chsh -s $brew_zsh \$USER"
        fi
    else
        echo "[SKIP] Homebrew zsh is already the default shell"
    fi
}

set_default_shell_linux() {
    echo "[STEP] Setting Zsh as default shell..."

    local zsh_path login_shell
    zsh_path=$(which zsh 2>/dev/null)
    login_shell="$(_login_shell_linux)"

    if [ -z "$zsh_path" ]; then
        echo "[WARN] zsh is not installed — skipping"
        return 0
    fi

    if [ "$login_shell" != "$zsh_path" ]; then
        echo "[INFO] Current login shell: ${login_shell:-unknown}"

        # Add zsh to /etc/shells if not present
        if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
            echo "[SUDO] Adding zsh to /etc/shells..."
            if echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null 2>&1; then
                echo "[OK] Added zsh to /etc/shells"
            else
                echo "[WARN] Could not add to /etc/shells (requires sudo)"
            fi
        fi

        # Try to change shell. `chsh` asks PAM for a password, which it cannot
        # do when stdin is not a terminal (piped installs) — and with stderr
        # sent to /dev/null the failure was silent, so the login shell quietly
        # stayed /bin/bash and none of this config ever loaded: no colours, no
        # prompt, no keybindings. Fall back to sudo, which the rest of this
        # script already relies on, and say why when both fail.
        if chsh -s "$zsh_path"; then
            echo "[OK] Default shell changed to zsh"
        elif sudo chsh -s "$zsh_path" "$USER"; then
            echo "[OK] Default shell changed to zsh (via sudo)"
        else
            echo "[WARN] Could not change default shell automatically"
            echo "[INFO] You can change it manually with:"
            echo "    sudo chsh -s \$(which zsh) \$USER"
        fi
        echo "[INFO] Log out and back in for the new login shell to take effect"
    else
        echo "[SKIP] Zsh is already the default shell"
    fi
}
