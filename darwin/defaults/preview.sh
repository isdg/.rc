#!/usr/bin/env bash
# Preview — PDF viewing

# Default page layout for PDFs: 1 = single page, continuous scroll.
# 0=single page, 1=single page continuous, 2=two-up, 3=two-up continuous.
defaults write com.apple.Preview kPDFDisplayMode -int 1

# Don't lay PDFs out as a book (facing pages with a lone cover) — that fights
# the single-page layout above whenever a two-up mode is in effect.
defaults write com.apple.Preview PVPDFDisplaysAsBook -bool false

# Note: Preview remembers a per-document view mode in com.apple.Preview.ViewState
# and restores it on reopen, so the default above only applies to PDFs this Mac
# hasn't opened before. Quit Preview before running this — a running app's prefs
# are cached by cfprefsd and will overwrite the write on exit.
