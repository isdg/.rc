#!/usr/bin/env bash
# Control Center menu-bar visibility

defaults write com.apple.controlcenter "NSStatusItem Visible BentoBox" -bool true
defaults write com.apple.controlcenter "NSStatusItem Visible ScreenMirroring" -bool false

# Bluetooth, Sound and Display pinned to the menu bar rather than living only
# inside the Control Center bento. One key each — the module's policy:
#
#   18  Show in Menu Bar
#   24  Show When Active
#    2  Don't Show in Menu Bar
#
# Writing `NSStatusItem Visible <Module>` alongside it, as the two lines above
# do for BentoBox and ScreenMirroring, is wrong for these three: ControlCenter
# discards that key and keeps its own bookkeeping instead. Checked by deleting
# every Sound key, writing only `Sound -int 18` and restarting ControlCenter --
# it regenerated "NSStatusItem VisibleCC Sound" and a "Preferred Position" of
# its own accord, and the item appeared. The policy is the whole declaration.
defaults write com.apple.controlcenter Bluetooth -int 18
defaults write com.apple.controlcenter Sound -int 18
defaults write com.apple.controlcenter Display -int 18

# Battery is already in the bar by default; this is the number next to the
# glyph. One key, not two — it is a display option on a module that is already
# showing, not a visibility policy, so the pair above does not apply.
defaults write com.apple.controlcenter BatteryShowPercentage -bool true

# The input menu — the ABC/Russian indicator — is not a Control Center module
# at all. It has its own agent and its own domain, so it needs neither key
# above and is not restarted by killall ControlCenter.
defaults write com.apple.TextInputMenu visible -bool true

# The other modules — WiFi, NowPlaying, FocusModes, UserSwitcher — are left at
# Apple's defaults on purpose: this machine never overrode them, so there is
# nothing of mine to reproduce.
