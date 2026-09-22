#!/usr/bin/env bash
# Lock screen — drop the account avatar and name, leaving the clock and the
# message alone. System-wide domain, so it needs sudo; guarded with `|| true`
# so a missing/declined sudo doesn't abort defaults.sh (set -e).
# Revert with: sudo defaults delete /Library/Preferences/com.apple.loginwindow

sudo defaults write /Library/Preferences/com.apple.loginwindow HideUserAvatarAndName -bool true || true
sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText -string "isg" || true
