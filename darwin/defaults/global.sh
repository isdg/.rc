#!/usr/bin/env bash
# NSGlobalDomain — system-wide

defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true
defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false
defaults write NSGlobalDomain AppleAntiAliasingThreshold -int 4
# Menu bar auto-hides (shows on hover); maximized windows take the full screen.
defaults write NSGlobalDomain _HIHideMenuBar -bool true

defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticInlinePredictionEnabled -bool false
defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false
