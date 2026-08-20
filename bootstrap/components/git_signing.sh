#!/usr/bin/env bash
# Component: make commit signing optional (shared)
#
# .gitconfig sets `commit.gpgsign = true` against a specific `user.signingkey`.
# That is right on a machine holding the key and fatal on one that does not:
# git refuses to write the object at all —
#
#     error: gpg failed to sign the data
#     fatal: failed to write commit object
#
# — so a freshly bootstrapped Linux box cannot commit until someone finds the
# flag. Rather than drop signing from the tracked config (it should stay on
# wherever the key exists), keep the default and let a machine-local file
# override it: .gitconfig includes ~/.gitconfig.local last, and this component
# writes `commit.gpgsign = false` there when the key is unavailable.
#
# The override is set through `git config --file`, one key at a time, so any
# other machine-local settings in that file are left untouched. When the key is
# present the override is removed rather than set to true, which lets the
# tracked default apply and keeps the local file empty on the usual machine.

GIT_LOCAL_CONFIG="$HOME/.gitconfig.local"

# The signing key named by the tracked .gitconfig, so this stays in step with it.
_git_signing_key() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.rc}"
    git config --file "$dotfiles_dir/.gitconfig" user.signingkey 2>/dev/null
}

# Is that key actually usable for signing on this machine?
_git_can_sign() {
    local key; key="$(_git_signing_key)"
    [ -n "$key" ] || return 1
    command -v gpg > /dev/null 2>&1 || return 1
    gpg --list-secret-keys "$key" > /dev/null 2>&1
}

ensure_git_signing() {
    echo "[STEP] Verifying commit signing..."

    local effective
    effective="$(git config --get commit.gpgsign 2>/dev/null)"

    if _git_can_sign; then
        if [ "$effective" = "true" ]; then
            echo "[OK] Commit signing on, key $(_git_signing_key) present"
        else
            echo "[FAIL] Signing key $(_git_signing_key) is present but commit.gpgsign is '$effective'"
            return 1
        fi
    else
        if [ "$effective" = "true" ]; then
            echo "[FAIL] commit.gpgsign is true but the key is unavailable — every commit here will fail"
            return 1
        fi
        echo "[OK] Commit signing off (no signing key on this machine)"
    fi
}

configure_git_signing() {
    echo "[STEP] Configuring commit signing..."

    if _git_can_sign; then
        # Let the tracked `gpgsign = true` stand.
        if [ -f "$GIT_LOCAL_CONFIG" ] && \
           git config --file "$GIT_LOCAL_CONFIG" --get commit.gpgsign > /dev/null 2>&1; then
            git config --file "$GIT_LOCAL_CONFIG" --unset commit.gpgsign
            echo "[OK] Signing key $(_git_signing_key) found — dropped the local override"
        else
            echo "[SKIP] Signing key $(_git_signing_key) found — signing stays on"
        fi
        return 0
    fi

    git config --file "$GIT_LOCAL_CONFIG" commit.gpgsign false

    if [ -z "$(_git_signing_key)" ]; then
        echo "[OK] No user.signingkey configured — signing disabled in $GIT_LOCAL_CONFIG"
    elif ! command -v gpg > /dev/null 2>&1; then
        echo "[OK] gpg not installed — signing disabled in $GIT_LOCAL_CONFIG"
    else
        echo "[OK] Key $(_git_signing_key) not in this machine's keyring — signing disabled in $GIT_LOCAL_CONFIG"
    fi
    echo "[INFO] Import the key and re-run to turn signing back on"
}
