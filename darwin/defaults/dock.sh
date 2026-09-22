#!/usr/bin/env bash
# Dock

defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock tilesize -int 60
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock showAppExposeGestureEnabled -bool true

# Hot corners
# corner values: 1=disabled, 2=Mission Control, 3=App windows, 4=Desktop,
# 5=Start screen saver, 6=Disable screen saver, 10=Display sleep,
# 11=Launchpad, 12=Notification Center, 13=Lock Screen, 14=Quick Note
# modifier: 0=none, 131072=Shift, 262144=Ctrl, 524288=Option, 1048576=Cmd
defaults write com.apple.dock wvous-bl-corner -int 13
defaults write com.apple.dock wvous-bl-modifier -int 1048576
defaults write com.apple.dock wvous-br-corner -int 4
defaults write com.apple.dock wvous-br-modifier -int 1048576

# Pinned apps, in Dock order. The stored tile also carries a bookmark blob and
# a label, but the Dock regenerates both from the path — so the path is the
# whole declaration, and _CFURLStringType 0 marks it a POSIX path, not a URL.
DOCK_APPS=(
    "/Applications/Safari.app"
    "/Applications/Spotify.app"
    "/Applications/Ghostty.app"
    "/System/Applications/Utilities/Activity Monitor.app"
    "/Applications/Google Chrome.app"
    "/System/Applications/Utilities/Terminal.app"
)

_dock_tile() {
    printf '<dict><key>tile-data</key><dict><key>file-data</key><dict>'
    printf '<key>_CFURLString</key><string>%s</string>' "$1"
    printf '<key>_CFURLStringType</key><integer>0</integer>'
    printf '</dict></dict></dict>'
}

# An app that isn't installed would pin as a "?" tile, so skip it. Bootstrap
# installs every app here but Chrome, which stays optional for that reason.
_dock_tiles=()
for _app in "${DOCK_APPS[@]}"; do
    if [ -e "$_app" ]; then
        _dock_tiles+=("$(_dock_tile "$_app")")
    fi
done

# Guard the empty case: `-array` with no elements would wipe the Dock instead.
if [ ${#_dock_tiles[@]} -gt 0 ]; then
    defaults write com.apple.dock persistent-apps -array "${_dock_tiles[@]}"
fi

# Modules are sourced into one shell, so clean up rather than leak into the next.
unset DOCK_APPS _dock_tiles _app
unset -f _dock_tile
