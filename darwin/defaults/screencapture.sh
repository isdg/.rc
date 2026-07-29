#!/usr/bin/env bash
# Screenshots

# Skip the floating thumbnail preview so a capture writes to disk immediately.
# With the thumbnail on, macOS defers the file write until the preview times out
# (~5s), which also delays the Hammerspoon watcher that copies it to the
# clipboard (hammerspoon/screenshot_clip.lua). Off = instant file + instant copy.
defaults write com.apple.screencapture show-thumbnail -bool false
