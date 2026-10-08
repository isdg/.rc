#!/usr/bin/env bash
# Component: ewl — source checkout in $HOME (shared)
#
# A checkout and nothing else: unlike plc, hr, omni and orchbus this component
# builds nothing and puts no binary on PATH, so ensure only asks whether the
# working copy is there.
#
# SSH rather than HTTPS, because unlike those four this repo is private. An
# anonymous HTTPS clone cannot read it and stops to ask for a username, which
# on an unattended run is a hang with no explanation -- the same shape of bug
# as the /etc/shells sudo prompt.
#
# So git runs here with every prompt it could raise disabled, and a machine
# without SSH access fails in seconds instead of parking bootstrap on a
# question nobody is watching:
#
#   BatchMode=yes                  no key-passphrase prompt, no host-key prompt
#   ConnectTimeout=15              bounds a network stall
#   StrictHostKeyChecking=accept-new   a first-ever contact with github.com
#                                  records the key rather than failing on it;
#                                  a *changed* key still fails, as it should
#   GIT_TERMINAL_PROMPT=0          no HTTPS username prompt, should the URL
#                                  ever be switched back
#
# Set per command rather than exported, so sourcing this file cannot change how
# git behaves for any other component.

EWL_REPO="git@github.com:isdg/ewl.git"
EWL_SRC="$HOME/ewl"
_EWL_SSH="ssh -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new"

ensure_ewl() {
    echo "[STEP] Verifying ewl checkout..."
    if [ -d "$EWL_SRC/.git" ]; then
        echo "[OK] ewl checked out ($EWL_SRC)"
        return 0
    fi
    echo "[FAIL] ewl not checked out (expected $EWL_SRC)"
    return 1
}

install_ewl() {
    echo "[STEP] Cloning ewl..."

    if [ -d "$EWL_SRC/.git" ]; then
        echo "[INFO] ewl already present at $EWL_SRC — pulling latest..."
        GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="$_EWL_SSH" \
            git -C "$EWL_SRC" pull --ff-only \
            || echo "[WARN] git pull ewl failed — leaving the checkout as-is."
        return 0
    fi

    # Something is at the path but is not a checkout. Do not clone over it and
    # do not move it aside; bootstrap has no business guessing what it is.
    if [ -e "$EWL_SRC" ]; then
        echo "[WARN] $EWL_SRC exists and is not a git checkout — leaving it alone."
        return 0
    fi

    if GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="$_EWL_SSH" \
        git clone "$EWL_REPO" "$EWL_SRC"; then
        echo "[OK] ewl cloned to $EWL_SRC"
    else
        # Never fatal. ewl is a checkout nothing else in bootstrap depends on,
        # so a machine without SSH access should still finish its run.
        echo "[WARN] Could not clone ewl — it is private, so this machine most"
        echo "       likely has no SSH key on the GitHub account."
        echo "[INFO] Check with:  ssh -T git@github.com"
        echo "[INFO] Then re-run bootstrap, or: git clone $EWL_REPO $EWL_SRC"
    fi
    return 0
}
