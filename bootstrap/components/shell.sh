#!/usr/bin/env bash
# Component: Set default shell (shared)

# Append $1 to /etc/shells, asking for a password only when there is a terminal
# to ask on, and never returning nonzero in a way that can abort the run.
#
# This used to be `sudo tee -a /etc/shells > /dev/null 2>&1`, which hid sudo's
# password prompt while sudo sat on the terminal waiting for an answer to it. An
# interactive bootstrap therefore looked like it had frozen after the fzf step,
# with nothing on screen saying why -- and everything queued behind this one
# (the keyboard remap, then every EXTRA component) never ran at all.
#
# So: use cached credentials silently if we have them, ask visibly if there is
# someone to ask, and warn instead of blocking if there is not.
_add_to_etc_shells() {
    local shell_path="$1"

    # -x -F: /bin/zsh must not count as a match for /opt/homebrew/bin/zsh, which
    # a substring grep would have done, silently skipping the append.
    if grep -qxF "$shell_path" /etc/shells 2>/dev/null; then
        return 0
    fi

    if sudo -n true 2>/dev/null; then
        if printf '%s\n' "$shell_path" | sudo -n tee -a /etc/shells >/dev/null; then
            echo "[OK] Added $shell_path to /etc/shells"
            return 0
        fi
        echo "[WARN] Could not add $shell_path to /etc/shells"
        return 1
    fi

    if [ ! -t 0 ] && [ ! -r /dev/tty ]; then
        echo "[WARN] Need sudo to add $shell_path to /etc/shells, and no terminal to ask on"
        echo "[INFO] Run:  echo $shell_path | sudo tee -a /etc/shells"
        return 1
    fi

    # ^D rather than ^C: ^C signals the whole process group and would take the
    # rest of bootstrap with it, which is the failure this function exists to
    # prevent. ^D makes sudo exit nonzero and we carry on to the next component.
    echo "[SUDO] Adding $shell_path to /etc/shells — enter your password (^D to skip):"
    if printf '%s\n' "$shell_path" | sudo tee -a /etc/shells >/dev/null; then
        echo "[OK] Added $shell_path to /etc/shells"
        return 0
    fi

    echo "[WARN] Could not add $shell_path to /etc/shells"
    echo "[INFO] Run:  echo $shell_path | sudo tee -a /etc/shells"
    return 1
}

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

    if [ "$SHELL" = "$brew_zsh" ]; then
        echo "[SKIP] Homebrew zsh is already the default shell"
        return 0
    fi

    echo "[INFO] Current shell: $SHELL"

    # chsh refuses a shell that is not in /etc/shells, so a failure there makes
    # the chsh below a guaranteed-to-fail password prompt. Skip it instead.
    if ! _add_to_etc_shells "$brew_zsh"; then
        echo "[WARN] Skipping chsh: $brew_zsh is not a permitted login shell yet"
        return 0
    fi

    # Unsilenced for the same reason as the sudo above: chsh asks for a password
    # too, and `2>/dev/null` made that prompt invisible.
    echo "[INFO] Running chsh (may ask for your password)"
    if chsh -s "$brew_zsh"; then
        echo "[OK] Default shell changed to Homebrew zsh"
        echo "[INFO] Log out and back in for it to take effect"
    else
        echo "[WARN] Could not change the default shell automatically"
        echo "[INFO] Run:  chsh -s $brew_zsh"
    fi

    # Never propagate a failure: the shell is worth setting, but not worth
    # losing the components that run after this one.
    return 0
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

        _add_to_etc_shells "$zsh_path" || true

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
