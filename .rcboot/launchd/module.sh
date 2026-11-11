#!/usr/bin/env bash
# Module: the launchd jobs in darwin/launchd (Darwin only), linked into
# ~/Library/LaunchAgents and loaded, so each runs at every login.

[ "$RC_OS" = darwin ] || return 0

for plist in "$DOTFILES_DIR"/darwin/launchd/com.local.*.plist; do
    link "darwin/launchd/${plist##*/}" \
        "$HOME/Library/LaunchAgents/${plist##*/}"
done

# Loading runs the job at once (RunAtLoad), so only a job that is not loaded
# or whose link moved is loaded again; after editing a plist, agents.sh load.
load_launchd_jobs() {
    local plist label
    for plist in "$DOTFILES_DIR"/darwin/launchd/com.local.*.plist; do
        label="$(basename "$plist" .plist)"
        if _link_changed "darwin/launchd/$label.plist" \
            || ! launchctl print "gui/$(id -u)/$label" > /dev/null 2>&1
        then
            "$DOTFILES_DIR/darwin/launchd/agents.sh" load \
                "${label#com.local.}"
        fi
    done
}

ensure_launchd_jobs() {
    local plist label rc=0
    for plist in "$DOTFILES_DIR"/darwin/launchd/com.local.*.plist; do
        label="$(basename "$plist" .plist)"
        if launchctl print "gui/$(id -u)/$label" > /dev/null 2>&1; then
            echo "[OK] $label loaded"
        else
            echo "[FAIL] $label not loaded" \
                "(darwin/launchd/agents.sh load ${label#com.local.})"
            rc=1
        fi
    done
    return $rc
}
hook load_launchd_jobs ensure_launchd_jobs
