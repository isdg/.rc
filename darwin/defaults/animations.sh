#!/usr/bin/env bash
# Animations — make switching apps and windows instant.
#
# Cmd-Tab itself has no animation. What you feel is what happens *after* the
# switch: if the target app lives on another Space (or is fullscreen), macOS
# slides the entire desktop across, and that slide is the delay. Reduce Motion
# replaces it with a quick cross-fade — it is the single biggest win here.
#
# Same switch as System Settings > Accessibility > Display > Reduce motion.
# WindowServer reads it at login, so if switching still slides after this, flip
# it once in System Settings (or log out and back in) to make it stick.
defaults write com.apple.universalaccess reduceMotion -bool true

# Window open / close / resize animations (AppKit apps).
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Dock. defaults/dock.sh sets autohide, so both the reveal delay and the slide
# duration sit between the pointer and a click.
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

# Mission Control and App Exposé — dock.sh enables the App Exposé gesture, and
# that zoom-out is the other switching animation. 0 makes windows appear without
# flying; 0.1 keeps just enough motion to follow where they went.
defaults write com.apple.dock expose-animation-duration -float 0.1

# No bouncing icon while an app launches.
defaults write com.apple.dock launchanim -bool false

# Delay before dragging a window to the screen edge switches Space.
defaults write com.apple.dock workspaces-edge-delay -float 0.1

# Legacy (Mavericks-era) request to drop the Space-switch swoosh entirely rather
# than fade it. WindowServer may well ignore it on current macOS — the write is
# accepted and harmless either way, and there is no supported replacement.
defaults write com.apple.dock workspaces-swoosh-animation-off -bool true

# Finder's own animations (window zoom, copy/move).
defaults write com.apple.finder DisableAllAnimations -bool true

# Revert:
#   defaults write com.apple.universalaccess reduceMotion -bool false
#   defaults delete NSGlobalDomain NSAutomaticWindowAnimationsEnabled
#   defaults delete NSGlobalDomain NSWindowResizeTime
#   defaults delete com.apple.dock autohide-delay
#   defaults delete com.apple.dock autohide-time-modifier
#   defaults delete com.apple.dock expose-animation-duration
#   defaults delete com.apple.dock launchanim
#   defaults delete com.apple.dock workspaces-edge-delay
#   defaults delete com.apple.finder DisableAllAnimations
#   killall Dock Finder
