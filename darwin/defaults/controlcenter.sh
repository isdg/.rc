#!/usr/bin/env bash
# Control Center menu-bar visibility

defaults write com.apple.controlcenter "NSStatusItem Visible BentoBox" -bool true
defaults write com.apple.controlcenter "NSStatusItem Visible ScreenMirroring" -bool false

# The other modules — WiFi, Bluetooth, Sound, NowPlaying, Battery, Display,
# FocusModes, UserSwitcher — are left at Apple's defaults on purpose: this
# machine never overrode them, so there is nothing of mine to reproduce.
