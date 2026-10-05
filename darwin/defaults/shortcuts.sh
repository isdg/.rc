#!/usr/bin/env bash
# System keyboard shortcuts (System Settings > Keyboard > Keyboard Shortcuts)

# 8 = Move focus to the Dock, on 🌐D instead of ⌃F3.
# parameters: (ascii 'd', keycode 2, fn modifier mask 0x800000)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 8 \
    '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>100</integer><integer>2</integer><integer>8388608</integer></array><key>type</key><string>standard</string></dict></dict>'

# Shortcuts are read at login; this reloads them now.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
